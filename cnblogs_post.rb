require 'metaweblog/post'
require 'time'

module MetaWeblog
  class CnblogsPost
    def self.members
      [:title, :description, :categories, :dateCreated]
    end

    def initialize(args)
      @data={}
      raise "The argument is not Hash." unless args.is_a?(Hash)
      h=args
      data = self.class.members.map{|m| (h[m]||h[m.to_s])}
      self.class.members.each_with_index do |member,i|
        self.__send__ "#{member}=",data[i] if data[i]
      end
    end

    def [](m)
      @data[m]
    end

    def to_h
      @data.dup
    end

    members.each do |member|
      define_method member do
        @data[member]
      end

      define_method "#{member}=" do |val|
        @data[member]=val
      end
    end

    def pub_date=(pub_date)
      @data[:pubDate] = case pub_date
                        when String then Time.parse(pub_date)
                        when Time, DateTime then pub_date
                        else
                          raise ArgumentError, "The argument is not String, Time and DateTime."
                        end
    end

    alias :pubDate= :pub_date=

  end
end
