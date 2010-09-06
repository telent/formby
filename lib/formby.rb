require 'erector'

# Erector 0.8.0 doesn't work properly with ruby 1.9 because of the
# changed behaviour of Array#to_s.  This is a very temporary fix

class Erector::Output
  def to_s ;  Erector::RawString.new(buffer.join "") ;end
end

# similarly, it uses uniq in a place where uniq doesn't work
class ExternalRenderer
  def rendered_externals(type)
    dep=@classes.map do |klass|
      klass.dependencies(type)
    end.flatten
    Hash[dep.map{|x| [[x.text,x.options],x]}].values
  end
end

module Formby
  # Formby::Base is the ancestor of pretty much everything
  class Base < Erector::Widget
    needs :name=>nil

    # The name of the widget.  Formby::Container provides an
    # elementary form of namespacing - if the widget is inside a named
    # container, the container's name plus "/" will be prepended to
    # this name when the widget is output.  See #fullname

    attr_reader :name

    # We maintain a distinction between the real value of a widget,
    # which is some kind of Ruby object (e.g. a string, or a number,
    # or a date, or a keyword), and the serialised representations of
    # this value that we write out when rendering the widget or read
    # in when processing form data.  #value always refers to the
    # real Ruby value, not to the serialised form
    #
    # The (de)serialisation may be simple (e.g. in the case of a
    # string-valued widget, the default is simply to trim leading and
    # trailing space from the user-supplied string), or more
    # complicated (for example, a widget allowing date/time entry may
    # transform its associated form data into a Ruby Time object).
    #
    # Subclass writers should note that deserialisation rules are
    # implemented in #from_request_params (which you should override
    # when writing a new widget if you don't want the default
    # behaviour) and serialisation is accomplished in #content (which
    # you will need to implement anyway)

    attr_accessor :value

    # Set the value of this widget, and recursively, its children from
    # GET/POST data.  
    #
    # +hash+ is request data as returned by Rack::Response#params

    def from_request_params(hash)
      value_from_hash(hash,nil)
    end

    # Erector calls this to output your widget
    def content(*args)
      raise NoMethodError.new("no such method",:content)
    end

    # Compute the full name of the widget including prefixes from
    # containing widgets.  This only works correctly inside a call to
    # #content or similar (i.e. as the widget is being output),
    # because it relies on the widget.parent chain existing.

    def fullname 
      parents=[]
      p=self
      while p
        if (p.respond_to?(:name) and p.name) then parents.unshift p.name end
        p = if p.respond_to?(:parent) then p.parent else nil end
      end
      parents.join("/")
    end

    # Some widgets depend on JQuery to do exciting JS stuff.  
    # Override this to tell Formby where to find your jquery/addons
    def self.jquery_location(filename=nil)
      filename ? "/static/js/#{filename}" : "/static/js/jquery-1.3.2.js"
    end        
  end


  # Simple widgets may (usually do) inherit from Formby::Input 

  class Input < Base
    needs :id=>nil,:value=>nil,:style=>nil,:readonly=>false

    def standard_attributes
      {  :name=>self.fullname, :id=>(@id and @id.to_s),:value=>@value, :type=>self.type, :style=>@style, :readonly=>@readonly }
    end
    def content
      input self.standard_attributes
    end

    def parse_value(string)
      if string then
        string=string.strip
        if string.empty?  then nil else string end
      end
    end
    
    def value_from_hash(hash,prefix)
      name=self.name.to_s
      if prefix then name = prefix+"/"+name end
      self.value=self.parse_value(hash[name])
    end
  end

  # Base class for container widgets

  class Container < Base
    attr_accessor :children
    needs :children,:params=>nil
    def initialize(*args)
      super
      @params and self.from_request_params(@params) 
    end
    def child(name) 
      @children.find do |c|
        c.name == name
      end
    end
    def value
      v={}
      @children.each { |c| v[c.name]=c.value }
      v
    end

    # This is called by from_request_params or by itself recursively.
    # +prefix+ is used for recursive calls to child widgets.  If you are
    # implementing a widget, prefix this to your widget names when
    # looking for your fields in +hash+ - see Formby::Input#value_from_hash
    # for example

    def value_from_hash(hash,prefix)
      if self.name then
        prefix=prefix ? (prefix+"/"+self.name.to_s) : (self.name.to_s)
      end
      @children.each { |c| 
        c.value_from_hash(hash,prefix) 
      }
    end
  end

  class Form < Container
  end 
      

  # Formby::Text in addition to the usual options accepts :inlinelabel
  # to provide placeholder text which is displayed inside the input
  # element when nothing has been typed by the user.
  #
  # The label has CSS class +intra-field-label+, so you can style it
  # to be grey and italicised or in some other way distinct from
  # actual entered text
  #
  # The jquery plugin this relies on is buggy (see source comment) - 
  # a better and more elegant replacement would be welcome
  # 
  class Text < Input
    depends_on :js,jquery_location
    depends_on :js,jquery_location("jquery.inlineFieldLabel.js")
    needs :inlinelabel=>nil
    def type ; :text ;end
    def content
      input self.standard_attributes
      if @inlinelabel then
        # javascript quote escaping
        i=(@inlinelabel).gsub(/(['"])/) {|x| "\\"+x}
        jquery "$('input[name=#{self.fullname}]').inlineFieldLabel({label:'#{i}'});"
        if self.value then
          v=(self.value).gsub(/(['"])/) {|x| "\\"+x}
          # gavri's inline label plugin seems to be buggy and ignores a
          # non-default value in the page html
          jquery "$('input[name=#{self.fullname}]').removeClass('intra-field-label').val('#{v}')"
        end
      end
    end
  end
  class Password < Input ; def type ; :password; end ; end
  class Hidden < Input;  def type ; :hidden; end ; end
  class Checkbox < Formby::Input
    def type ; :checkbox; end ; 
    def content
      input self.standard_attributes.merge(:value=>true,:checked=>self.value ? :checked : nil)
    end
  end

  # Produce a 'textarea' element.  Does not accept :rows,:cols attribute -
  # use CSS to set the box dimensions instead.
  class Textarea < Formby::Input
    def type ; nil; end ; 
    def content
      textarea self.standard_attributes.merge(:value=>nil) do
        text self.value
      end
    end
  end

  # Create a 'select' element with 'option' subelements.
  # Accepts the attribute +:options+, a hash table of (value => label)
  # specifying the valid options
  class Dropdown < Formby::Input
    needs :options
    def type ; :nil; end
    def content
      select self.standard_attributes.merge(:value=>nil) do
        @options.each do |k,v|
          option :value=>k,:selected=>(k==self.value) do
            text v
          end
        end
      end
    end
  end
  
  # attribute +:label+ sets the button text
  class Button < Formby::Input
    def type; :button ;end
    needs :label
    def standard_attributes(*args)
      # whoever wrote this bit of the html forms spec was smoking something
      hash=super
      hash[:value]=@label
      hash
    end
  end
  class Submit < Formby::Button
    def type; :submit ;end
  end
end
