require 'rails_helper'
describe WebhookListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let(:report_identity) { Reports::UpdateAccountIdentity.new(account, Time.zone.now) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }
  let!(:message) do
    create(:message, message_type: 'outgoing',
                     account: account, inbox: inbox, conversation: conversation)
  end
  let!(:message_created_event) { Events::Base.new(event_name, Time.zone.now, message: message) }
  let!(:conversation_created_event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation) }

  describe '#message_created' do
    let(:event_name) { :'message.created' }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.message_created(message_created_event)
      end
    end

    context 'when webhook is configured' do
      it 'triggers webhook' do
        webhook = create(:webhook, inbox: inbox, account: account)
        expect(WebhookJob).to receive(:perform_later).with(webhook.url, message.webhook_data.merge(event: 'message_created')).once
        listener.message_created(message_created_event)
      end
    end

    context 'when inbox is an API Channel' do
      it 'triggers webhook if webhook_url is present' do
        channel_api = create(:channel_api, account: account)
        api_inbox = channel_api.inbox
        api_conversation = create(:conversation, account: account, inbox: api_inbox, assignee: user)
        api_message = create(
          :message,
          message_type: 'outgoing',
          account: account,
          inbox: api_inbox,
          conversation: api_conversation
        )
        api_event = Events::Base.new(event_name, Time.zone.now, message: api_message)
        expect(WebhookJob).to receive(:perform_later).with(channel_api.webhook_url, api_message.webhook_data.merge(event: 'message_created')).once
        listener.message_created(api_event)
      end

      it 'does not trigger webhook if webhook_url is not present' do
        channel_api = create(:channel_api, webhook_url: nil, account: account)
        api_inbox = channel_api.inbox
        api_conversation = create(:conversation, account: account, inbox: api_inbox, assignee: user)
        api_message = create(
          :message,
          message_type: 'outgoing',
          account: account,
          inbox: channel_api.inbox,
          conversation: api_conversation
        )
        api_event = Events::Base.new(event_name, Time.zone.now, message: api_message)
        expect(WebhookJob).not_to receive(:perform_later)
        listener.message_created(api_event)
      end
    end
  end

  describe '#conversation_created' do
    let(:event_name) { :'conversation.created' }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.conversation_created(conversation_created_event)
      end
    end

    context 'when webhook is configured' do
      it 'triggers webhook' do
        webhook = create(:webhook, inbox: inbox, account: account)
        expect(WebhookJob).to receive(:perform_later).with(webhook.url, conversation.webhook_data.merge(event: 'conversation_created')).once
        listener.conversation_created(conversation_created_event)
      end
    end

    context 'when inbox is an API Channel' do
      it 'triggers webhook if webhook_url is present' do
        channel_api = create(:channel_api, account: account)
        api_inbox = channel_api.inbox
        api_conversation = create(:conversation, account: account, inbox: api_inbox, assignee: user)
        api_event = Events::Base.new(event_name, Time.zone.now, conversation: api_conversation)
        expect(WebhookJob).to receive(:perform_later).with(channel_api.webhook_url,
                                                           api_conversation.webhook_data.merge(event: 'conversation_created')).once
        listener.conversation_created(api_event)
      end

      it 'does not trigger webhook if webhook_url is not present' do
        channel_api = create(:channel_api, webhook_url: nil, account: account)
        api_inbox = channel_api.inbox
        api_conversation = create(:conversation, account: account, inbox: api_inbox, assignee: user)
        api_event = Events::Base.new(event_name, Time.zone.now, conversation: api_conversation)
        expect(WebhookJob).not_to receive(:perform_later)
        listener.conversation_created(api_event)
      end
    end
  end
end