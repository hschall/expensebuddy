class PagesController < ApplicationController
  def turbo_test
  end

  def turbo_test_response
    render turbo_stream: turbo_stream.replace("test_area", "<div style='color: red;'>🔥 Turbo Replaced This</div>")
  end
end
