if Rails.version == '4.2.0'
  # Fixed in 4.2.1
  module ActiveRecord
    module Transactions

      protected

      # Restore the new record state and id of a record that was previously saved by a call to save_record_state.
      def restore_transaction_record_state(force = false) #:nodoc:
        unless @_start_transaction_state.empty?
          transaction_level = (@_start_transaction_state[:level] || 0) - 1
          if transaction_level < 1 || force
            restore_state = @_start_transaction_state
            thaw
            @new_record = restore_state[:new_record]
            @destroyed  = restore_state[:destroyed]
            pk = self.class.primary_key
            if pk && read_attribute(pk) != restore_state[:id]
              write_attribute(pk, restore_state[:id])
            end
            freeze if restore_state[:frozen?]
          end
        end
      end
    end
  end
end
