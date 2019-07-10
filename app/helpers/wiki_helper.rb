# frozen_string_literal: true

module WikiHelper
  include API::Helpers::RelatedResourcesHelpers

  # Produces a pure text breadcrumb for a given page.
  #
  # page_slug - The slug of a WikiPage object.
  #
  # Returns a String composed of the capitalized name of each directory and the
  # capitalized name of the page itself.
  def breadcrumb(page_slug)
    page_slug.split('/')
      .map { |dir_or_page| WikiPage.unhyphenize(dir_or_page).capitalize }
      .join(' / ')
  end

  def wiki_breadcrumb_dropdown_links(page_slug)
    page_slug_split = page_slug.split('/')
    page_slug_split.pop(1)
    current_slug = ""
    page_slug_split
      .map do |dir_or_page|
        current_slug = "#{current_slug}#{dir_or_page}/"
        add_to_breadcrumb_dropdown link_to(WikiPage.unhyphenize(dir_or_page).capitalize, project_wiki_path(@project, current_slug)), location: :after
      end
  end

  def wiki_page_errors(error)
    return unless error

    content_tag(:div, class: 'alert alert-danger') do
      case error
      when WikiPage::PageChangedError
        page_link = link_to s_("WikiPageConflictMessage|the page"), project_wiki_path(@project, @page), target: "_blank"
        concat(
          (s_("WikiPageConflictMessage|Someone edited the page the same time you did. Please check out %{page_link} and make sure your changes will not unintentionally remove theirs.") % { page_link: page_link }).html_safe
        )
      when WikiPage::PageRenameError
        s_("WikiEdit|There is already a page with the same title in that path.")
      else
        error.message
      end
    end
  end

  def wiki_attachment_upload_url
    expose_url(api_v4_projects_wikis_attachments_path(id: @project.id))
  end

  def wiki_sort_controls(sort_params = {}, &block)
    sort = sort_params[:sort] || ProjectWiki::TITLE_ORDER
    currently_desc = sort_params[:direction] == 'desc'
    link_class = 'btn btn-default has-tooltip reverse-sort-btn qa-reverse-sort'
    reversed_direction = currently_desc ? 'asc' : 'desc'
    icon_class = currently_desc ? 'highest' : 'lowest'

    link_to(yield(sort_params.merge(sort: sort, direction: reversed_direction)),
      type: 'button', class: link_class, title: _('Sort direction')) do
      sprite_icon("sort-#{icon_class}", size: 16)
    end
  end

  def wiki_sort_title(key)
    if key == ProjectWiki::CREATED_AT_ORDER
      s_("Wiki|Created date")
    else
      s_("Wiki|Title")
    end
  end

  def wiki_show_children_title(show_children)
    icon_name, icon_text =
      if show_children == ProjectWiki::NESTING_TREE
        ['folder-open', s_("Wiki|Show folder contents")]
      elsif show_children == ProjectWiki::NESTING_CLOSED
        ['folder-o', s_("Wiki|Hide folder contents")]
      else
        ['list-bulleted', s_("Wiki|Show files separately")]
      end

    sprite_icon_with_text(icon_name, icon_text, size: 16)
  end

  def wiki_pages_wiki_page_link(wiki_page, nesting, project, current_dir = '')
    wiki_page_link = link_to wiki_page.title, project_wiki_path(project, wiki_page), class: 'wiki-page-title'
    case nesting
    when ProjectWiki::NESTING_FLAT
      tags = []
      wiki_dir = WikiDirectory.new(wiki_page.directory)
      while wiki_dir.slug != current_dir
        path = project_wiki_dir_path(project, wiki_dir)
        tags.unshift content_tag(:span, '/', class: 'wiki-page-name-separator')
        tags.unshift link_to(wiki_dir.title, path, class: 'wiki-page-dir-name')
        wiki_dir = WikiDirectory.new(wiki_dir.directory)
      end

      tags << wiki_page_link
      tags.join('').html_safe
    else
      wiki_page_link
    end
  end
end
