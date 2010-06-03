require File.dirname(__FILE__) + '/../spec_helper'
require 'prawn'

describe "Filtering via Verity IF" do

  before(:all) do
    pdf = Prawn::Document.new
    pdf.text "The PDF's Text"
    @pdf_body = pdf.render
  end


  it "should convert a PDF document's body to HTML" do
    obj = mock("obj", { :body => @pdf_body, :id => 2001, :file_extension => 'pdf' });
    Infopark::SES::Filter::html_via_verity(obj).should include 'The PDF&#39;s Text'
  end

end
