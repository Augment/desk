require 'faraday'

# @private
module Faraday
  # @private
  class Response::RaiseHttp4xx < Response::Middleware
    def on_complete(env)
      case env[:status].to_i
      when 400
        raise Desk::BadRequest.new(error_message(env), env[:response_headers])
      when 401
        raise Desk::Unauthorized.new(error_message(env), env[:response_headers])
      when 403
        raise Desk::Forbidden.new(error_message(env), env[:response_headers])
      when 404
        raise Desk::NotFound.new(error_message(env), env[:response_headers])
      when 406
        raise Desk::NotAcceptable.new(error_message(env), env[:response_headers])
      when 409
        raise Desk::Conflict.new(error_message(env), env[:response_headers])
      when 422
        raise Desk::Unprocessable.new(error_message(env), env[:response_headers])
      when 429
        raise Desk::EnhanceYourCalm.new(error_message(env), env[:response_headers])
      end
    end

    private

    def error_message(env)
      "#{env[:method].to_s.upcase} #{env[:url].to_s}: #{env[:status]}#{error_body(env[:body])}"
    end

    def error_body(body)
      if body.nil?
        nil
      elsif body['error']
        ": #{body['error']}"
      elsif body['errors']
        first = body['errors'].to_a.first
        if first.is_a? Hash
          ": #{first['message'].chomp}"
        else
          ": #{first.chomp}"
        end
      elsif body['raw']
        error_message = ": #{body['raw']['message']}"
        return error_message unless body.errors.present?

        field, code = body.errors.first
        while code.nil? || (words = validation_error_code_in_words(field, code.first)).nil? do
          if code.first.is_a? String
            f, code = code.first
          else
            f, code = code.first.to_a.first
          end
        end
        error_message += words.to_s
        error_message
      end
    end

    def validation_error_code_in_words(field, code)
      return unless code.is_a? String
      {
        blank: ": #{field}: value has not been set and is required",
        existence: ": #{field}: value does not exist",
        taken: ": #{field}: value has already been taken and must be unique",
        inclusion: ": #{field}: value is not an available choice",
        exclusion: ": #{field}: value is reserved",
        too_short: ": #{field}: string value is too short",
        too_long: ": #{field}: string value is too long",
        invalid: ": #{field}: value is invalid, please see documentation for resource specifics"
      }[code.to_sym]
    end
  end
end
