require 'rails_helper'
require 'support/gravity_helper'

describe Admin::AssetsController, type: :controller do
  context 'with a submission' do
    before do
      allow_any_instance_of(Admin::AssetsController).to receive(:require_artsy_authentication)
      stub_gravity_root
      stub_gravity_user
      stub_gravity_user_detail
      stub_gravity_artist
      @submission = Submission.create!(artist_id: 'artistid', user_id: 'userid')
    end

    context 'fetching an asset' do
      it 'renders the show page if the asset exists' do
        asset = @submission.assets.create(asset_type: 'image')
        get :show, params: {
          submission_id: @submission.id,
          id: asset.id
        }
        expect(response).to render_template(:show)
      end

      it 'returns a 404 if the asset does not exist' do
        expect do
          get :show, params: {
            submission_id: @submission.id,
            id: 'foo'
          }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'renders a flash error if the original image cannot be found' do
        asset = @submission.assets.create(asset_type: 'image')
        expect_any_instance_of(Asset).to receive(:original_image).and_raise(Asset::GeminiHttpException)
        get :show, params: {
          submission_id: @submission.id,
          id: asset.id
        }
        expect(response).to render_template(:show)
        expect(assigns(:asset)['original_image']).to be_nil
      end
    end

    context 'creating assets for a submission' do
      it 'correctly adds the assets for a single token' do
        expect do
          post :multiple, params: {
            gemini_tokens: 'token1',
            submission_id: @submission.id,
            asset_type: 'image'
          }
        end.to change(@submission.assets, :count).by(1)
      end

      it 'correctly adds the assets for multiple tokens' do
        expect do
          post :multiple, params: {
            gemini_tokens: 'token1 token2 token3 token4',
            submission_id: @submission.id,
            asset_type: 'image'
          }
        end.to change(@submission.assets, :count).by(4)
      end

      it 'creates no assets for a single token' do
        expect do
          post :multiple, params: { gemini_tokens: '', submission_id: @submission.id, asset_type: 'image' }
        end.to_not change(@submission.assets, :count)
      end
    end
  end
end