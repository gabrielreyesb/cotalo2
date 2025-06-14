# Prevent Rails from wrapping fields with errors in a div, which breaks Bootstrap input-group layouts
ActionView::Base.field_error_proc = Proc.new { |html_tag, _| html_tag.html_safe } 