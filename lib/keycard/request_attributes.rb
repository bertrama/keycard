module Keycard
  class RequestAttributes
    def initialize(request, finder: InstitutionFinder.new)
      @finder = finder
      @request = request
    end

    def [](attr)
      all[attr]
    end

    def all
      finder.attributes_for(request)
    end

    private

    attr_reader :finder
    attr_reader :request
  end
end

