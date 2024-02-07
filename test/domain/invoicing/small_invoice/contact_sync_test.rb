# frozen_string_literal: true

#  Copyright (c) 2006-2020, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Invoicing
  module SmallInvoice
    class ContactSyncTest < ActiveSupport::TestCase
      include SmallInvoiceTestHelper

      test '#sync new client' do
        # updates people
        add_hans    = stub_add_entity(:people, client:, body: hans_json)
        add_andreas = stub_add_entity(:people, client:, body: andreas_json)

        subject.sync

        assert_requested(add_hans)
        assert_requested(add_andreas)
      end

      test '#sync existing client' do
        client.update_column(:invoicing_key, 1234)
        andreas.update_column(:invoicing_key, 2)

        # updates people
        add_hans     = stub_add_entity(:people,  client:, body: hans_json)
        edit_andreas = stub_edit_entity(:people, client:, key: 2, body: edit_andreas_json)

        subject_with_existing.sync

        assert_requested(add_hans)
        assert_requested(edit_andreas)
      end

      private

      def described_class
        Invoicing::SmallInvoice::ContactSync
      end

      def subject
        described_class.new(client, [])
      end

      def subject_with_existing
        described_class.new(client, [2])
      end

      def client
        clients(:puzzle)
      end

      def andreas
        contacts(:puzzle_rava)
      end

      def hans_json
        '{"surname":"Hauswart","name":"Hans","email":"hauswart@example.com","phone":null,"gender":"F"}'
      end

      def andreas_json
        '{"surname":"Rava","name":"Andreas","email":"rava@example.com","phone":null,"gender":"F"}'
      end

      def edit_andreas_json
        '{"surname":"Rava","name":"Andreas","email":"rava@example.com","phone":null,"gender":"F","id":"2"}'
      end
    end
  end
end
