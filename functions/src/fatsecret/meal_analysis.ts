import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import axios from "axios";

// Initialize Firebase Admin if not already done
if (!admin.apps.length) {
  admin.initializeApp();
}

// Interfaces
interface FatSecretConfig {
  clientId: string;
  clientSecret: string;
  tokenUrl: string;
  apiUrl: string;
}

interface DetectedFood {
  name: string;
  calories: number;
  carbs: number;
  protein: number;
  fat: number;
  saturatedFat: number;
  fiber: number;
  sugar: number;
  sodium: number;
  giValue?: number;
  glycemicLoad?: number;
  glCategory: string;
}

interface MealAnalysisResult {
  id: string;
  mealNumber: number;
  foods: DetectedFood[];
  totalGL: number;
  glCategory: string;
  error?: string;
}

interface MealImage {
  id: string;
  image_b64: string;
}

interface AnalysisRequest {
  images: MealImage[];
}

interface DietAssessmentReport {
  meals: MealAnalysisResult[];
  avgGLPerMeal: number;
  isHealthy: boolean;
  warnings: string[];
  mealCount: number;
  glThresholds: {
    low: number;
    medium: number;
    high: number;
  };
  processedAt: string;
}

interface AnalysisResponse {
  success: boolean;
  nutritionData: DietAssessmentReport;
}

interface GIBatchResponse {
  results: Array<{
    food_name: string;
    gi_value?: number;
    status: string;
    source?: string;
    error?: string;
  }>;
  summary: {
    total: number;
    found: number;
    not_found: number;
  };
}

// Configuration
const FATSECRET_CONFIG: FatSecretConfig = {
  clientId: process.env.FATSECRET_CLIENT_ID!,
  clientSecret: process.env.FATSECRET_CLIENT_SECRET!,
  tokenUrl: "https://oauth.fatsecret.com/connect/token",
  apiUrl: "https://platform.fatsecret.com/rest/image-recognition/v2",
};

// Flask GI API URL
const FLASK_GI_API = process.env.FLASK_API_URL;
if (!FLASK_GI_API) throw new Error("FLASK_API_URL not defined");

// GL thresholds (per meal average)
const GL_THRESHOLDS = {
  low: 10,
  medium: 20,
  high: 20,
};

// Rate limiting for FatSecret API
const FATSECRET_RATE_LIMIT = {
  maxConcurrent: 3,
  delayBetweenBatches: 1000,
};

/**
 * Get FatSecret OAuth token
 */
async function getFatSecretAccessToken(): Promise<string> {
  try {
    const response = await axios.post(
      FATSECRET_CONFIG.tokenUrl,
      "grant_type=client_credentials&scope=image-recognition",
      {
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        auth: {
          username: FATSECRET_CONFIG.clientId,
          password: FATSECRET_CONFIG.clientSecret,
        },
      }
    );
    return response.data.access_token;
  } catch (error: any) {
    console.error("FatSecret token error:", error.response?.data || error.message);
    throw new Error("Failed to authenticate with FatSecret API");
  }
}

/**
 * Analyze meal image with FatSecret API
 */
async function analyzeMealImage(imageBase64: string, accessToken: string): Promise<any> {
  try {
    const response = await axios.post(
      FATSECRET_CONFIG.apiUrl,
      { image_b64: imageBase64 },
      {
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        timeout: 30000,
      }
    );
    return response.data;
  } catch (error: any) {
    // Check if it's a FatSecret error response (211 - no food detected)
    if (error.response?.data?.error) {
      const errorData = error.response.data.error;
      if (errorData.code === 211) {
        console.log("❌ No food detected in image (Error 211)");
        return {
          error: {
            code: 211,
            message: "No food item detected in this image"
          }
        };
      }
    }

    console.error("FatSecret analysis error:", error.response?.data || error.message);
    throw new Error("Failed to analyze image");
  }
}

/**
 * Process multiple images concurrently with rate limiting
 */
async function processImagesConcurrently(
  images: MealImage[],
  accessToken: string
): Promise<Array<{image: MealImage, data: any, error?: string}>> {
  const results: Array<{image: MealImage, data: any, error?: string}> = [];

  const batchSize = FATSECRET_RATE_LIMIT.maxConcurrent;

  for (let i = 0; i < images.length; i += batchSize) {
    const batch = images.slice(i, i + batchSize);
    console.log(`🔄 Processing batch ${Math.floor(i/batchSize) + 1}, size: ${batch.length}`);

    const batchPromises = batch.map(async (image) => {
      try {
        const data = await analyzeMealImage(image.image_b64, accessToken);

        // Check if FatSecret returned an error (no food detected)
        if (data.error && data.error.code === 211) {
          console.log(`⚠️ Image ${image.id}: No food detected`);
          return {
            image,
            data: null,
            error: "No food item detected in this image. Please upload a photo that clearly shows food items."
          };
        }

        console.log(`📸 Image ${image.id} processed successfully`);
        return { image, data };
      } catch (error: any) {
        console.error(`❌ FatSecret API error for image ${image.id}:`, error.message);
        return { image, data: null, error: error.message };
      }
    });

    const batchResults = await Promise.all(batchPromises);
    results.push(...batchResults);

    if (i + batchSize < images.length) {
      await new Promise(resolve => setTimeout(resolve, FATSECRET_RATE_LIMIT.delayBetweenBatches));
    }
  }

  return results;
}

/**
 * Get GI values in batch
 */
async function getGIBatch(foodNames: string[]): Promise<Map<string, number>> {
  try {
    const uniqueFoodNames = [...new Set(foodNames)].filter(name =>
      name && name !== "Unknown Food" && name.trim().length > 0
    );

    if (uniqueFoodNames.length === 0) {
      return new Map();
    }

    console.log(`🍴 Batch searching GI for ${uniqueFoodNames.length} unique foods`);

    const response = await axios.post<GIBatchResponse>(
      `${FLASK_GI_API}/api/batch-search-gi`,
      { food_names: uniqueFoodNames },
      { timeout: 60000 }
    );

    console.log(`📊 Batch GI results: ${response.data.summary.found} found, ${response.data.summary.not_found} not found`);

    const giMap = new Map<string, number>();
    response.data.results.forEach(item => {
      if (item.status === "success" && item.gi_value !== undefined) {
        giMap.set(item.food_name.toLowerCase(), item.gi_value);
      }
    });

    return giMap;
  } catch (error: any) {
    console.error("❌ Batch GI search failed:", error.message);
    throw error;
  }
}

/**
 * Calculate Glycemic Load
 * GL = (GI × Net_Carbs) / 100
 * Net Carbs = Total Carbs - Fiber
 */
function calculateGlycemicLoad(giValue: number, carbs: number, fiber: number): number {
  const netCarbs = Math.max(0, carbs - fiber);
  const gl = (giValue * netCarbs) / 100;
  return Math.round(gl * 10) / 10;
}

/**
 * Get GL category
 */
function getGLCategory(gl: number): string {
  if (gl < GL_THRESHOLDS.low) return "low";
  if (gl < GL_THRESHOLDS.medium) return "medium";
  return "high";
}

/**
 * Extract food items and nutrition from FatSecret response
 */
function extractFoodData(apiResponse: any): Partial<DetectedFood>[] {
  const foods: Partial<DetectedFood>[] = [];

  try {
    if (apiResponse.food_response && Array.isArray(apiResponse.food_response)) {
      for (const foodItem of apiResponse.food_response) {
        if (foodItem.eaten && foodItem.eaten.total_nutritional_content) {
          const content = foodItem.eaten.total_nutritional_content;
          const foodName = foodItem.food_entry_name || "Unknown Food";

          foods.push({
            name: foodName,
            calories: parseFloat(content.calories || 0),
            carbs: parseFloat(content.carbohydrate || 0),
            protein: parseFloat(content.protein || 0),
            fat: parseFloat(content.fat || 0),
            saturatedFat: parseFloat(content.saturated_fat || 0),
            fiber: parseFloat(content.fiber || 0),
            sugar: parseFloat(content.sugar || 0),
            sodium: parseFloat(content.sodium || 0),
          });
        }
      }
    }
  } catch (error) {
    console.error("❌ Error extracting food data:", error);
  }

  console.log(`🍎 Extracted ${foods.length} foods`);
  return foods;
}

/**
 * Process single meal with GI data
 */
async function processMealWithGI(
  image: MealImage,
  mealNumber: number,
  apiResponse: any,
  giMap: Map<string, number>
): Promise<MealAnalysisResult> {
  const foods = extractFoodData(apiResponse);

  if (foods.length === 0) {
    console.warn(`⚠️ No foods detected in image ${image.id}`);
    return {
      id: image.id,
      mealNumber,
      foods: [],
      totalGL: 0,
      glCategory: "unknown",
      error: "No food item detected in this image. Please upload a photo that clearly shows food items.",
    };
  }

  // Calculate GL for each food using GI map
  let mealTotalGL = 0;
  const foodsWithGL: DetectedFood[] = [];

  for (const food of foods) {
    const giValue = giMap.get(food.name!.toLowerCase()) || null;

    if (giValue !== null) {
      const gl = calculateGlycemicLoad(giValue, food.carbs!, food.fiber!);
      mealTotalGL += gl;

      foodsWithGL.push({
        name: food.name!,
        calories: food.calories!,
        carbs: food.carbs!,
        protein: food.protein!,
        fat: food.fat!,
        saturatedFat: food.saturatedFat!,
        fiber: food.fiber!,
        sugar: food.sugar!,
        sodium: food.sodium!,
        giValue,
        glycemicLoad: gl,
        glCategory: getGLCategory(gl),
      });
    } else {
      // Food without GI data
      foodsWithGL.push({
        name: food.name!,
        calories: food.calories!,
        carbs: food.carbs!,
        protein: food.protein!,
        fat: food.fat!,
        saturatedFat: food.saturatedFat!,
        fiber: food.fiber!,
        sugar: food.sugar!,
        sodium: food.sodium!,
        giValue: undefined,
        glycemicLoad: undefined,
        glCategory: "unknown",
      });
    }
  }

  console.log(`✅ Meal ${mealNumber}: ${foodsWithGL.length} foods, GL: ${mealTotalGL.toFixed(1)}`);

  return {
    id: image.id,
    mealNumber,
    foods: foodsWithGL,
    totalGL: Math.round(mealTotalGL * 10) / 10,
    glCategory: getGLCategory(mealTotalGL),
  };
}

/**
 * Assess diet quality based on average GL per meal
 */
function assessDietQuality(mealGLs: number[]): {
  isHealthy: boolean;
  warnings: string[];
  avgGL: number;
} {
  const warnings: string[] = [];

  // Calculate average GL per meal
  const avgGL = mealGLs.reduce((sum, gl) => sum + gl, 0) / mealGLs.length;

  let isHealthy = true;

  if (avgGL > GL_THRESHOLDS.high) {
    warnings.push(
      `High average glycemic load (${avgGL.toFixed(1)}) - may cause frequent blood sugar spikes`
    );
    isHealthy = false;
  } else if (avgGL > GL_THRESHOLDS.medium) {
    warnings.push(
      `Moderate average glycemic load (${avgGL.toFixed(1)}) - consider reducing high-GI foods`
    );
  }

  const highGLMeals = mealGLs.filter(gl => gl > GL_THRESHOLDS.high).length;
  if (highGLMeals > mealGLs.length * 0.4) {
    warnings.push(
      `${highGLMeals} out of ${mealGLs.length} meals have high GL - try to balance with low-GI foods`
    );
    isHealthy = false;
  }

  const veryHighGL = mealGLs.filter(gl => gl > 30).length;
  if (veryHighGL > 0) {
    warnings.push(
      `${veryHighGL} meal(s) have very high GL (>30) - consider portion control`
    );
    isHealthy = false;
  }

  return { isHealthy, warnings, avgGL };
}

/**
 * Main Cloud Function
 */
export const analyzeMealPhotos = functions.https.onCall(
  async (data: AnalysisRequest, context: functions.https.CallableContext): Promise<AnalysisResponse> => {
    try {
      // Auth check
      if (!context.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "User must be authenticated"
        );
      }

      // Validate input
      if (!data.images || !Array.isArray(data.images) || data.images.length < 1) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "At least 1 meal image required"
        );
      }

      if (data.images.length > 9) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Maximum 9 meal images allowed"
        );
      }

      console.log(`🍽️ Analyzing ${data.images.length} meals for user ${context.auth.uid}`);

      const accessToken = await getFatSecretAccessToken();

      // 1. Process all images concurrently
      console.log("🔄 Starting concurrent image analysis...");
      const imageResults = await processImagesConcurrently(data.images, accessToken);

      // 2. Collect food names from successful analyses
      const allFoodNames: string[] = [];
      const validImageResults: Array<{image: MealImage, data: any}> = [];

      for (const result of imageResults) {
        if (result.data && !result.error) {
          const foods = extractFoodData(result.data);
          foods.forEach(food => {
            if (food.name && food.name !== "Unknown Food") {
              allFoodNames.push(food.name);
            }
          });
          validImageResults.push({ image: result.image, data: result.data });
        }
      }

      // 3. Batch get GI values
      console.log(`🔍 Collecting GI values for ${allFoodNames.length} food items...`);

      let giMap: Map<string, number>;
      try {
        giMap = await getGIBatch(allFoodNames);
      } catch (error: any) {
        console.error("❌ Batch GI failed, using empty map: ", error.message);
        giMap = new Map();
      }

      // 4. Process each meal result
      const mealResults: MealAnalysisResult[] = [];
      const allMealGLs: number[] = [];

      for (let i = 0; i < imageResults.length; i++) {
        const result = imageResults[i];

        // Handle images with errors (no food detected)
        if (result.error) {
          console.log(`⚠️ Image ${result.image.id} has error: ${result.error}`);
          mealResults.push({
            id: result.image.id,
            mealNumber: i + 1,
            error: result.error,
            foods: [],
            totalGL: 0,
            glCategory: "unknown",
          });
          continue;
        }

        // Process valid images
        if (result.data) {
          try {
            const mealResult = await processMealWithGI(
              result.image,
              i + 1,
              result.data,
              giMap
            );
            mealResults.push(mealResult);

            // Only count meals without errors for GL calculation
            if (!mealResult.error && mealResult.totalGL > 0) {
              allMealGLs.push(mealResult.totalGL);
            }
          } catch (error: any) {
            console.error(`❌ Error processing image ${result.image.id}:`, error.message);
            mealResults.push({
              id: result.image.id,
              mealNumber: i + 1,
              error: error.message,
              foods: [],
              totalGL: 0,
              glCategory: "unknown",
            });
          }
        }
      }

      // Sort by original order
      mealResults.sort((a, b) => {
        const indexA = data.images.findIndex(img => img.id === a.id);
        const indexB = data.images.findIndex(img => img.id === b.id);
        return indexA - indexB;
      });

      // Assess overall diet quality (only from valid meals)
      const validGLs = allMealGLs.filter(gl => gl > 0);
      const validMealCount = mealResults.filter(m => !m.error && m.totalGL > 0).length;

      const assessment = validGLs.length > 0
        ? assessDietQuality(validGLs)
        : {
          isHealthy: false,
          warnings: ["Unable to calculate GL - no valid food data found"],
          avgGL: 0
        };

      // Prepare response
      const nutritionData: DietAssessmentReport = {
        meals: mealResults,
        avgGLPerMeal: Math.round(assessment.avgGL * 10) / 10,
        isHealthy: assessment.isHealthy,
        warnings: assessment.warnings,
        mealCount: validMealCount, // Only count valid meals
        glThresholds: GL_THRESHOLDS,
        processedAt: new Date().toISOString(),
      };

      console.log("✨ Analysis completed:", {
        userId: context.auth.uid,
        totalImages: data.images.length,
        validMeals: validMealCount,
        errorMeals: mealResults.filter(m => m.error).length,
        avgGL: assessment.avgGL.toFixed(1),
        isHealthy: assessment.isHealthy,
        foodsWithGI: giMap.size,
      });

      return {
        success: true,
        nutritionData,
      };

    } catch (error: any) {
      console.error("💥 Error in analyzeMealPhotos:", error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        error.message || "Failed to analyze meal photos"
      );
    }
  }
);