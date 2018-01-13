require 'spec_helper'

describe Projects::VariablesController do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_master(user)
  end

  describe 'POST #create' do
    context 'variable is valid' do
      it 'shows a success flash message' do
        post :create, namespace_id: project.namespace.to_param, project_id: project,
                      variable: { key: "one", value: "two" }

        expect(flash[:notice]).to include 'Variable was successfully created.'
        expect(response).to redirect_to(project_settings_ci_cd_path(project))
      end
    end

    context 'variable is invalid' do
      it 'renders show' do
        post :create, namespace_id: project.namespace.to_param, project_id: project,
                      variable: { key: "..one", value: "two" }

        expect(response).to render_template("projects/variables/show")
      end
    end
  end

  describe 'POST #update' do
    let(:variable) { create(:ci_variable) }

    context 'updating a variable with valid characters' do
      before do
        project.variables << variable
      end

      it 'shows a success flash message' do
        post :update, namespace_id: project.namespace.to_param, project_id: project,
                      id: variable.id, variable: { key: variable.key, value: 'two' }

        expect(flash[:notice]).to include 'Variable was successfully updated.'
        expect(response).to redirect_to(project_variables_path(project))
      end

      it 'renders the action #show if the variable key is invalid' do
        post :update, namespace_id: project.namespace.to_param, project_id: project,
                      id: variable.id, variable: { key: '?', value: variable.value }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template :show
      end
    end
  end

  describe 'POST #save_multiple' do
    let(:variable) { create(:ci_variable) }

    before do
      project.variables << variable
    end

    context 'with invalid new variable parameters' do
      subject do
        post :save_multiple,
          namespace_id: project.namespace.to_param, project_id: project,
          variables: [{ key: variable.key, value: 'other_value' },
                      { key: '..?', value: 'dummy_value' }],
          format: :json
      end

      it 'does not update the existing variable' do
        expect { subject }.not_to change { variable.reload.value }
      end

      it 'does not create the new variable' do
        expect { subject }.not_to change { project.variables.count }
      end

      it 'returns a bad request response' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with valid new variable parameters' do
      subject do
        post :save_multiple,
          namespace_id: project.namespace.to_param, project_id: project,
          variables: [{ key: variable.key, value: 'other_value' },
                      { key: 'new_key', value: 'dummy_value' }],
          format: :json
      end

      it 'updates the existing variable' do
        expect { subject }.to change { variable.reload.value }.to('other_value')
      end

      it 'creates the new variable' do
        expect { subject }.to change { project.variables.count }.by(1)
      end

      it 'returns a successful response' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with a deleted variable' do
      subject do
        post :save_multiple,
          namespace_id: project.namespace.to_param, project_id: project,
          variables: [{ key: variable.key, value: variable.value, _destroy: 'true' }],
          format: :json
      end

      it 'destroys the variable' do
        expect { subject }.to change { project.variables.count }.by(-1)
        expect { variable.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it 'returns a successful response' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
