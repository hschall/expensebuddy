module ApplicationHelper
  def sortable(column, title = nil)
    title ||= column.titleize
    direction = (column == params[:sort] && params[:direction] == "asc") ? "desc" : "asc"
    link_to title, request.query_parameters.merge(sort: column, direction: direction), class: "text-decoration-none"
  end
end
