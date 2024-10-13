const { withAppBuildGradle } = require('@expo/config-plugins');

module.exports = function withReactNativeCameraGradle(config) {
  return withAppBuildGradle(config, config => {
    if (config.modResults.contents) {
      config.modResults.contents = config.modResults.contents.replace(
        /defaultConfig {([^}]*)}/,
        (match, p1) =>
          `defaultConfig {${p1}\n        missingDimensionStrategy 'react-native-camera', 'general'\n    }`,
      );
    }
    return config;
  });
};
