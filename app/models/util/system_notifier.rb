require 'pathname'

class SystemNotifier < ActionMailer::Base

  def exception_notification(controller, request, exception)
    @subject = sprintf("[ERROR] %s\#%s (%s)",
                       controller.controller_name,
                       controller.action_name,
                       exception.class)
    @body = { 'controller'       => controller,
              'request'          => request,
              'exception'        => exception,
              'backtrace'        => sanitize_backtrace(exception.backtrace),
              'protected_params' => blackout_hash(request.parameters, 'pwd'),
              'host'             => request.env['HTTP_HOST'],
              'rails_root'       => rails_root }
    @sent_on    = Time.zone.now
    @from       = SYSTEM_EMAIL
    @recipients = EXCEPTION_RECIPIENTS
    @headers    = {}
  end

  private

  def sanitize_backtrace(trace)
    re = Regexp.new(/^#{Regexp.escape(rails_root)}/)
    trace.map do |line|
      Pathname.new(line.gsub(re, '[RAILS_ROOT]')).cleanpath.to_s
    end
  end

  def rails_root
    @rails_root ||= Pathname.new(RAILS_ROOT).cleanpath.to_s
  end

  def blackout_hash(hash, *keys)
    dupe = hash.dup
    dupe.each_pair do |key, value|
      if keys.include? key
        dupe[key] = '[FILTERED]'
      elsif value.is_a? Hash
        dupe[key] = blackout_hash(value, *keys)
      end
    end
    dupe
  end

end
