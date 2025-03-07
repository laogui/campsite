# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Comments
      class TasksControllerTest < ActionDispatch::IntegrationTest
        include Devise::Test::IntegrationHelpers

        setup do
          html = <<~HTML.strip
              <ul class="task-list" data-type="taskList">
              <li class="task-item" data-checked="false" data-type="taskItem">
                <label><input type="checkbox"><span></span></label>
                <div><p>Unchecked</p></div>
              </li>
              <li class="task-item" data-checked="true" data-type="taskItem">
                <label><input type="checkbox" checked="checked"><span></span></label>
                <div><p>Checked</p></div>
              </li>
            </ul>
          HTML
          @comment = create(:comment, body_html: html)
          @member = @comment.member
          @organization = @comment.member.organization
        end

        context "#update" do
          test "author can mark a task checked" do
            sign_in @member.user
            put organization_comment_tasks_path(@organization.slug, @comment.public_id),
              params: { index: 0, checked: true },
              as: :json

            assert_response :ok
            assert_response_gen_schema

            doc = Nokogiri::HTML.fragment(@comment.reload.body_html)

            assert_equal "true", doc.css("li")[0].attr("data-checked")
            assert_equal "checked", doc.css("input")[0].attr("checked")
          end

          test "author can mark a task unchecked" do
            sign_in @member.user
            put organization_comment_tasks_path(@organization.slug, @comment.public_id),
              params: { index: 1, checked: false },
              as: :json

            assert_response :ok
            assert_response_gen_schema

            doc = Nokogiri::HTML.fragment(@comment.reload.body_html)

            assert_equal "false", doc.css("li")[1].attr("data-checked")
            assert_not_equal "checked", doc.css("input")[1].attr("checked")
          end

          test "org member can mark a task checked" do
            sign_in create(:organization_membership, organization: @organization).user
            put organization_comment_tasks_path(@organization.slug, @comment.public_id),
              params: { index: 1, checked: false },
              as: :json

            assert_response :ok
            assert_response_gen_schema
          end

          test "query count" do
            sign_in @member.user

            assert_query_count 10 do
              put organization_comment_tasks_path(@organization.slug, @comment.public_id),
                params: { index: 0, checked: true },
                as: :json
            end
          end

          test "random member cannot mark a task checked" do
            sign_in create(:user)
            put organization_comment_tasks_path(@organization.slug, @comment.public_id),
              params: { index: 1, checked: false },
              as: :json

            assert_response :forbidden
          end

          test "unauthed cannot mark a task checked" do
            put organization_comment_tasks_path(@organization.slug, @comment.public_id),
              params: { index: 1, checked: false },
              as: :json

            assert_response :unauthorized
          end
        end
      end
    end
  end
end
