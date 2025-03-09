const globals = require("globals");
const pluginJs = require("@eslint/js");
const tseslint = require("@typescript-eslint/eslint-plugin");
const tsparser = require("@typescript-eslint/parser");
const importPlugin = require("eslint-plugin-import");

module.exports = [
  {
      // ✅ 继承 ESLint 官方推荐配置
      ...pluginJs.configs.recommended,
      languageOptions: {
        ...pluginJs.configs.recommended.languageOptions,
        globals: { ...globals.node }, // ✅ 确保 Node.js 全局变量可用
      },
    },
    {
      files: ["**/*.ts", "**/*.tsx"],
      ignores: ["lib/**/*", "generated/**/*", "eslint.config.js"],
      languageOptions: {
        ecmaVersion: "latest",
        sourceType: "module", // ✅ ESM，改成 "script" 适配 CommonJS
        parser: tsparser,
        parserOptions: {
          project: ["tsconfig.json", "tsconfig.dev.json"],
        },
        globals: { ...globals.node }, // ✅ 解决 require, module, exports 的 no-undef 问题
      },
      plugins: {
        "@typescript-eslint": tseslint,
        "import": importPlugin,
      },
      rules: {
        "quotes": ["error", "double"],
        "import/no-unresolved": "off",
        "indent": ["error", 2],
      },
    },
];
