require 'hexapdf'

def retrieve_field(pdf, field_name)
  field_refs = pdf.pages.map { |p| p[:Annots] }.flatten
  fields = field_refs.map { |ref| pdf.object(ref) }
  fields.select { |f| f[:T] == field_name }[0]
end

# Fill in and save left-aligned form
left_name = "./form-left.pdf"
left_doc = HexaPDF::Document.open(left_name)

field = retrieve_field(left_doc, "address")
field[:V] = "Address"


left_doc.catalog[:AcroForm][:NeedAppearances] = true

left_doc.task(:optimize, compact: true,
              object_streams: :delete)

left_filled_in = "./filled-in-left.pdf"
left_doc.write(left_filled_in)

# Fill in and save right-aligned form
right_name = "./form-right.pdf"
right_doc = HexaPDF::Document.open(right_name)

field = retrieve_field(right_doc, "address")
field[:V] = "Address"

right_doc.catalog[:AcroForm][:NeedAppearances] = true

right_doc.task(:optimize, compact: true,
               object_streams: :delete)


right_filled_in = "./filled-in-right.pdf"
right_doc.write(right_filled_in)

# Combine forms, starting with left-aligned, then right-aligned
combined_left_then_right = HexaPDF::Document.new
[left_filled_in, right_filled_in].each do |filename|
  pdf = HexaPDF::Document.open(filename)
  pdf.pages.each { |page| combined_left_then_right.pages << combined_left_then_right.import(page) }
end

(combined_left_then_right.catalog[:AcroForm] = {})[:NeedAppearances] = true

combined_left_then_right.task(:optimize, compact: true,
              object_streams: :delete)

combined_left_then_right_name = "./combined_left_then_right.pdf"
combined_left_then_right.write(combined_left_then_right_name)

# At this point, if viewed in Preview for Mac or Chrome or Acrobat,
# combined_left_then_right.pdf has the left-aligned page followed the right-aligned page,
# and the fields are aligned accordingly.

# So far, so expected.  Now for the crazy bit.
# Combine forms, starting with right-aligned, then left-aligned
combined_right_then_left = HexaPDF::Document.new
[right_filled_in, left_filled_in].each do |filename|
  pdf = HexaPDF::Document.open(filename)
  pdf.pages.each { |page| combined_right_then_left.pages << combined_right_then_left.import(page) }
end

(combined_right_then_left.catalog[:AcroForm] = {})[:NeedAppearances] = true

combined_right_then_left.task(:optimize, compact: true,
              object_streams: :delete)

combined_right_then_left_name = "./combined_right_then_left.pdf"
combined_right_then_left.write(combined_right_then_left_name)

# At this point, if viewed in Preview for Mac or Chrome or Acrobat,
# combined_right_then_left.pdf has the right-aligned page followed the left-aligned page,
# and the fields are aligned accordingly.
#
# But:
# In Preview for Mac, they're aligned accordingly (right, then left)
# In Acrobat and Chrome, they're both right-aligned

# So, somehow, in Acrobat and Chrome, when in combining documents
# and there are fields in both documents with the same name,
# and the first is right-aligned and the second is left-aligned (but not if it's the other way around),
# it ignores the alignment information for the field in the second document,
# or overrides it with the alignment from the first.


