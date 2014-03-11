module Twitter
  module Mongoize
    def self.included(base)
      base.extend(ClassMethods)
    end
  
    module ClassMethods
      # Get the object as it was stored in the database, and instantiate
      # this custom class from it.
      def demongoize(mongoized)               
        if mongoized
          symbolized = {}
          mongoized.map { |k,v| symbolized[k.to_sym] = v }
          self.new(symbolized)
        else
          nil
        end
      end

      # Takes any possible object and converts it to how it would be
      # stored in the database.
      def mongoize(object)
        case object
        when self then object.mongoize
        when Hash then self.new(object).mongoize
        else object
        end
      end

      # Converts the object that was supplied to a criteria and converts it
      # into a database friendly form.
      def evolve(object)
        case object
        when self then object.mongoize
        else object
        end
      end
    end 
  
    # Converts an object of this instance into a database friendly value.
    def mongoize
      self.attrs
    end  
  
  end
end

class Twitter::User
  include Twitter::Mongoize
end
class Twitter::Status
  include Twitter::Mongoize
end