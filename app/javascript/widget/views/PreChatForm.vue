<template>
  <div class="flex flex-1 overflow-auto">
    <pre-chat-form :options="preChatFormOptions" @submit="onSubmit" />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import PreChatForm from '../components/PreChat/Form';
import configMixin from '../mixins/configMixin';
import routerMixin from '../mixins/routerMixin';

export default {
  components: {
    PreChatForm,
  },
  mixins: [configMixin, routerMixin],
  computed: {
    ...mapGetters({
      conversationSize: 'conversation/getConversationSize',
    }),
  },
  watch: {
    conversationSize(newSize, oldSize) {
      if (!oldSize && newSize > oldSize) {
        this.replaceRoute('messages');
      }
    },
  },
  methods: {
    onSubmit({ fullName, phoneNumber, emailAddress, message, activeCampaignId }) {
      if (activeCampaignId) {
        bus.$emit('execute-campaign', activeCampaignId);
        this.$store.dispatch('contacts/update', {
          contact: {
	    email: emailAddress,
            name: fullName,
		 },
          phone_number: phoneNumber,
        });
      } else {
        this.$store.dispatch('conversation/createConversation', {
          fullName: fullName,
          emailAddress: emailAddress,
          phoneNumber: phoneNumber,
          message: message,
        });
      }
    },
  },
};
</script>
