export default {
  methods: {
    useInstallationName(str = '', installationName) {
      return str.replace(/Omnichannel/g, installationName);
    },
  },
};
