# frozen_string_literal: true

module QA
  module Page
    module Project
      class Menu < Page::Base
        include SubMenus::Common

        include SubMenus::CiCd
        include SubMenus::Issues
        include SubMenus::Operations
        include SubMenus::Repository
        include SubMenus::Settings

        view 'app/views/layouts/nav/sidebar/_project.html.haml' do
          element :activity_link
          element :merge_requests_link
          element :wiki_link
        end

        view 'app/assets/javascripts/fly_out_nav.js' do
          element :fly_out, "classList.add('fly-out-list')" # rubocop:disable QA/ElementWithPattern
        end

        def click_merge_requests
          within_sidebar do
            click_element(:merge_requests_link)
          end
        end

        def click_wiki
          within_sidebar do
            click_element(:wiki_link)
          end
        end

        def go_to_activity
          within_sidebar do
            click_element(:activity_link)
          end
        end
      end
    end
  end
end
