require 'formby'
require 'pp'

class Formby::Vanilla < Formby::Input
  def type ; :text ;end
end

class Formby::Hbox < Formby::Container
  def content
    table do
      tr do
        self.children.each do |c|
          td c.name.to_s
          td widget c
        end
      end
    end
  end
end

describe Formby do
  it "Formby::Input accepts name,id,value,style attributes" do
    s=Formby::Vanilla.new(:name=>:worzel, :id=>:gummidge, :style=>"leather", :value=>43).to_html
    [/worzel/,/gummidge/,/leather/,/43/].each do |r|
      s.should match r
    end
  end
  it "Formby::Container accepts children" do
    Names=[:foo,:bar,:baz]
    kids=Names.map {|x| Formby::Vanilla.new(:name=>x) }
    w=Formby::Container.new(:name=>:form,:children=>kids)
    def w.content
      table do
        Names.each do |f| 
          tr do
            td f.to_s
            td { widget child(f) }
          end
        end
      end
    end
    out=w.to_html
    Names.each do |n|
      out.should match Regexp.new(%Q[input name="form/#{n.to_s}"])
    end
  end
  it "Formby::Container#value returns a hash of values" do
    Names=[:foo,:bar,:baz]
    data={"ctr/foo"=>"23","ctr/bar"=>"88","ctr/baz"=>"999"}
    kids=Names.map {|x| Formby::Vanilla.new(:name=>x) }
    w=Formby::Container.new(:children=>kids,:name=>:ctr)    
    w2=Formby::Container.new(:children=>[w])
    w2.from_request_params(data)
    w2.value.should == {:ctr=>{:foo=>"23", :bar=>"88", :baz=>"999"}}
  end
  it "Formby::Container accepts a :params arg" do
    Names=[:foo,:bar,:baz]
    data={"ctr/foo"=>"23","ctr/bar"=>"88","ctr/baz"=>"999"}
    kids=Names.map {|x| Formby::Vanilla.new(:name=>x) }
    w=Formby::Container.new(:children=>kids,:name=>:ctr)    
    w2=Formby::Container.new(:children=>[w], :params=>data)
    w2.value.should == {:ctr=>{:foo=>"23", :bar=>"88", :baz=>"999"}}
  end
  it "Formby::Text accepts :inlinelabel arg and does jquery stuff with it" do
    tx=Formby::Text.new(:name=>:text,:inlinelabel=>"search behind sofa")
    w=Formby::Hbox.new(:children=>[tx],:name=>:ctr)    

    w.to_html.should include %Q[input name="ctr/text" type="text"]
    w.to_html.should include %Q[inlineFieldLabel({label:'search behind sofa'})]

    page=Erector::Widgets::Page.new(:w=>w)
    def page.body_content
      h1 "a headline"
      widget @w
    end
    page.to_html.should include %Q[inlineFieldLabel.js]

  end
  it "Formby::Text with assigned value does js call to remove default value styling" do
    tx=Formby::Text.new(:name=>:text,:inlinelabel=>"search behind sofa",
                        :value=>"fifty pence")
    w=Formby::Hbox.new(:children=>[tx],:name=>:ctr)    
    w.to_html.should include %Q[inlineFieldLabel({label:'search behind sofa'})]    
    w.to_html.should include %Q[$('input[name=ctr/text]').removeClass('intra-field-label').val('fifty pence')]
  end
  it "Formby::Checkbox translates a booleanish value into :checked attribute presence/absence" do
    w=Formby::Checkbox.new(:name=>:tick,:value=>true)
    w.to_html.should include %Q[input checked="checked"]
    w=Formby::Checkbox.new(:name=>:tick,:value=>nil)
    w.to_html.should_not include %Q[checked]
  end
  it "Formby::Textarea produces a 'textarea' element" do
    s=Formby::Textarea.new(:name=>:story,:value=>"Once upon a time").to_html
    s.should include %Q[<textarea]
    s.should include %Q[name=\"story\"]
    s.should include %Q[Once upon a time]
  end
  # XXX need to test widgets with names/other attributes that confuse 
  # javascript quoting

end
