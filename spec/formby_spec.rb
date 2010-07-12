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
    s=Formby::Vanilla.new(:name=>:worzel, :id=>:gummidge, :style=>"leather", :value=>43).to_s
    [/worzel/,/gummidge/,/leather/,/43/].each do |r|
      s.should match r
    end
  end
  it "Formby::Input can set its value from a rack-style param[] hash" do
    w=Formby::Vanilla.new(:name=>:worzel, :id=>:gummidge, :style=>"leather", :value=>43)
    h={"worzel"=>" trimmable text ","gummidge"=> "123455678"}
    w.from_form(h)
    w.value.should == "trimmable text"
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
    out=w.to_s
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
    w2.from_form(data)
    w2.value.should == {:ctr=>{:foo=>"23", :bar=>"88", :baz=>"999"}}
  end
  it "Formby::Text accepts :inlinelabel arg and does jquery stuff with it" do
    tx=Formby::Text.new(:name=>:text,:inlinelabel=>"search behind sofa")
    w=Formby::Hbox.new(:children=>[tx],:name=>:ctr)    

    w.to_s.should include %Q[input name="ctr/text" type="text"]
    w.to_s.should include %Q[inlineFieldLabel({label:'search behind sofa'})]    

    # this gives me the creeps.  +page+ has no reference at all to 
    # tx or any other widget with external deps, so how does it know
    # to output them?  I'll be happy when this test starts failing
    page=Erector::Widgets::Page.new
    page.to_s.should include %Q[inlineFieldLabel.js]

  end
  it "Formby::Text with assigned value does js call to remove default value styling" do
    tx=Formby::Text.new(:name=>:text,:inlinelabel=>"search behind sofa",
                        :value=>"fifty pence")
    w=Formby::Hbox.new(:children=>[tx],:name=>:ctr)    
    w.to_s.should include %Q[inlineFieldLabel({label:'search behind sofa'})]    
    w.to_s.should include %Q[$('input[name=ctr/text]').removeClass('intra-field-label').val('fifty pence')]
  end
  it "Formby::Checkbox translates a booleanish value into :checked attribute presence/absence" do
    w=Formby::Checkbox.new(:name=>:tick,:value=>true)
    w.to_s.should include %Q[input checked="checked"]
    w=Formby::Checkbox.new(:name=>:tick,:value=>nil)
    w.to_s.should_not include %Q[checked]
  end
  it "Formby::Textarea produces a 'textarea' element" do
    s=Formby::Textarea.new(:name=>:story,:value=>"Once upon a time").to_s
    s.should include %Q[<textarea]
    s.should include %Q[name=\"story\"]
    s.should include %Q[Once upon a time]
  end
  # XXX need to test widgets with names/other attributes that confuse 
  # javascript quoting

end
