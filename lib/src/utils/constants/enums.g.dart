// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DietPreferenceAdapter extends TypeAdapter<DietPreference> {
  @override
  final int typeId = 8;

  @override
  DietPreference read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DietPreference.vegan;
      case 1:
        return DietPreference.vegetarian;
      case 2:
        return DietPreference.paleo;
      case 3:
        return DietPreference.whole30;
      default:
        return DietPreference.vegan;
    }
  }

  @override
  void write(BinaryWriter writer, DietPreference obj) {
    switch (obj) {
      case DietPreference.vegan:
        writer.writeByte(0);
        break;
      case DietPreference.vegetarian:
        writer.writeByte(1);
        break;
      case DietPreference.paleo:
        writer.writeByte(2);
        break;
      case DietPreference.whole30:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DietPreferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AllergenAdapter extends TypeAdapter<Allergen> {
  @override
  final int typeId = 9;

  @override
  Allergen read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Allergen.egg;
      case 1:
        return Allergen.dairy;
      case 2:
        return Allergen.gluten;
      case 3:
        return Allergen.nut;
      case 4:
        return Allergen.grain;
      default:
        return Allergen.egg;
    }
  }

  @override
  void write(BinaryWriter writer, Allergen obj) {
    switch (obj) {
      case Allergen.egg:
        writer.writeByte(0);
        break;
      case Allergen.dairy:
        writer.writeByte(1);
        break;
      case Allergen.gluten:
        writer.writeByte(2);
        break;
      case Allergen.nut:
        writer.writeByte(3);
        break;
      case Allergen.grain:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllergenAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CookingMethodAdapter extends TypeAdapter<CookingMethod> {
  @override
  final int typeId = 10;

  @override
  CookingMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CookingMethod.airFryer;
      case 1:
        return CookingMethod.blender;
      case 2:
        return CookingMethod.grill;
      case 3:
        return CookingMethod.instantPot;
      case 4:
        return CookingMethod.mealPrep;
      case 5:
        return CookingMethod.noBake;
      case 6:
        return CookingMethod.oven;
      case 7:
        return CookingMethod.slowCooker;
      case 8:
        return CookingMethod.smoker;
      case 9:
        return CookingMethod.stovetop;
      case 10:
        return CookingMethod.foodProcessor;
      case 11:
        return CookingMethod.noCook;
      case 12:
        return CookingMethod.microwave;
      case 13:
        return CookingMethod.sheetPan;
      default:
        return CookingMethod.airFryer;
    }
  }

  @override
  void write(BinaryWriter writer, CookingMethod obj) {
    switch (obj) {
      case CookingMethod.airFryer:
        writer.writeByte(0);
        break;
      case CookingMethod.blender:
        writer.writeByte(1);
        break;
      case CookingMethod.grill:
        writer.writeByte(2);
        break;
      case CookingMethod.instantPot:
        writer.writeByte(3);
        break;
      case CookingMethod.mealPrep:
        writer.writeByte(4);
        break;
      case CookingMethod.noBake:
        writer.writeByte(5);
        break;
      case CookingMethod.oven:
        writer.writeByte(6);
        break;
      case CookingMethod.slowCooker:
        writer.writeByte(7);
        break;
      case CookingMethod.smoker:
        writer.writeByte(8);
        break;
      case CookingMethod.stovetop:
        writer.writeByte(9);
        break;
      case CookingMethod.foodProcessor:
        writer.writeByte(10);
        break;
      case CookingMethod.noCook:
        writer.writeByte(11);
        break;
      case CookingMethod.microwave:
        writer.writeByte(12);
        break;
      case CookingMethod.sheetPan:
        writer.writeByte(13);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CookingMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealPlanTypeAdapter extends TypeAdapter<MealPlanType> {
  @override
  final int typeId = 11;

  @override
  MealPlanType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MealPlanType.daily;
      case 1:
        return MealPlanType.weekly;
      default:
        return MealPlanType.daily;
    }
  }

  @override
  void write(BinaryWriter writer, MealPlanType obj) {
    switch (obj) {
      case MealPlanType.daily:
        writer.writeByte(0);
        break;
      case MealPlanType.weekly:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealPlanTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealPlanStatusAdapter extends TypeAdapter<MealPlanStatus> {
  @override
  final int typeId = 12;

  @override
  MealPlanStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MealPlanStatus.confirmed;
      case 1:
        return MealPlanStatus.completed;
      case 2:
        return MealPlanStatus.cancelled;
      case 3:
        return MealPlanStatus.expired;
      default:
        return MealPlanStatus.confirmed;
    }
  }

  @override
  void write(BinaryWriter writer, MealPlanStatus obj) {
    switch (obj) {
      case MealPlanStatus.confirmed:
        writer.writeByte(0);
        break;
      case MealPlanStatus.completed:
        writer.writeByte(1);
        break;
      case MealPlanStatus.cancelled:
        writer.writeByte(2);
        break;
      case MealPlanStatus.expired:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealPlanStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealTimeSlotAdapter extends TypeAdapter<MealTimeSlot> {
  @override
  final int typeId = 13;

  @override
  MealTimeSlot read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MealTimeSlot.breakfast;
      case 1:
        return MealTimeSlot.lunch;
      case 2:
        return MealTimeSlot.snack;
      case 3:
        return MealTimeSlot.dinner;
      default:
        return MealTimeSlot.breakfast;
    }
  }

  @override
  void write(BinaryWriter writer, MealTimeSlot obj) {
    switch (obj) {
      case MealTimeSlot.breakfast:
        writer.writeByte(0);
        break;
      case MealTimeSlot.lunch:
        writer.writeByte(1);
        break;
      case MealTimeSlot.snack:
        writer.writeByte(2);
        break;
      case MealTimeSlot.dinner:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealTimeSlotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealConsumptionStatusAdapter extends TypeAdapter<MealConsumptionStatus> {
  @override
  final int typeId = 14;

  @override
  MealConsumptionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MealConsumptionStatus.pending;
      case 1:
        return MealConsumptionStatus.consumed;
      case 2:
        return MealConsumptionStatus.skipped;
      default:
        return MealConsumptionStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, MealConsumptionStatus obj) {
    switch (obj) {
      case MealConsumptionStatus.pending:
        writer.writeByte(0);
        break;
      case MealConsumptionStatus.consumed:
        writer.writeByte(1);
        break;
      case MealConsumptionStatus.skipped:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealConsumptionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
