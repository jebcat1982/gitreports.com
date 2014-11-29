require 'spec_helper'

feature 'Repository' do
  let!(:organization) { create :organization }
  let!(:user) { create :user, username: 'greptest' }
  let!(:org_user) { create :user, organizations: [organization] }
  let!(:another_user) { create :user }
  let!(:repository) { create :user_repository, name: 'CoolCode', owner: user.username, users: [user] }
  let!(:org_repository) { create :repository, name: 'CoolOrg', organization: organization, users: [org_user] }
  let!(:inactive_repository) { create :repository, name: 'CoolInactive', is_active: false, users: [user] }

  describe 'show repository' do
    context 'holder does not exist' do
      scenario 'shows 404' do
        visit repository_public_path('joe_schmoe', inactive_repository.name)
        expect(page).to have_content('The repository you\'re looking for could not be located.')
      end
    end

    context 'repository is activated' do
      scenario 'shows the repository issue page' do
        visit repository_public_path(user.username, repository.name)
        expect(page).to have_content(repository.name)
      end
    end

    context 'repository is not activated' do
      scenario 'shows 404' do
        visit repository_public_path(user.username, inactive_repository.name)
        expect(page).to have_content('The repository you\'re looking for could not be located.')
      end
    end
  end

  describe 'edit repository' do
    context 'repository owner logged in' do
      before do
        log_in user
        visit profile_path
      end

      scenario 'edits the repository' do
        click_on 'CoolCode'
        click_on 'Edit' 
        fill_in 'Display name', with: 'The Coolest'
        fill_in 'Issue name', with: 'Big problems!'
        fill_in 'Prompt', with: 'Tell us what is wrong'
        fill_in 'Followup', with: 'Thanks!'
        fill_in 'Labels', with: 'problem'
        click_on 'Update'

        expect(page).to have_content('The Coolest')
        expect(page).to have_content('Big problems!')
        expect(page).to have_content('Tell us what is wrong')
        expect(page).to have_content('Thanks!')
        expect(page).to have_content('problem')
      end
    end

    context 'org user logged in' do
      before do
        log_in org_user
        visit profile_path
      end
      
      scenario 'edits the repository' do
        click_on 'CoolOrg'
        click_on 'Edit' 
        fill_in 'Display name', with: 'The Coolest'
        fill_in 'Issue name', with: 'Big problems!'
        fill_in 'Prompt', with: 'Tell us what is wrong'
        fill_in 'Followup', with: 'Thanks!'
        fill_in 'Labels', with: 'problem'
        click_on 'Update'

        expect(page).to have_content('The Coolest')
        expect(page).to have_content('Big problems!')
        expect(page).to have_content('Tell us what is wrong')
        expect(page).to have_content('Thanks!')
        expect(page).to have_content('problem')
      end
    end

    context 'another user logged in' do
      before { log_in another_user }
      
      scenario 'does not permit editing' do
        visit repository_edit_path(repository)
        expect(page).not_to have_content('Update Repository')
        visit repository_edit_path(org_repository)
        expect(page).not_to have_content('Update Repository')
      end
    end
  end

  describe 'activates and deactivates repository' do
    context 'repository owner logged in' do
      before do
        log_in user
        visit profile_path
      end

      scenario 'deactivates and reactivates the repository' do
        click_on 'CoolCode'
        expect(page).to have_content('Status: Active')
        click_on 'Deactivate'
        expect(page).to have_content('Status: Inactive')
        click_on 'Activate'
        expect(page).to have_content('Status: Active')
      end
    end

    context 'org user logged in' do
      before do
        log_in org_user
        visit profile_path
      end
      
      scenario 'edits the repository' do
        click_on 'CoolOrg'
        expect(page).to have_content('Status: Active')
        click_on 'Deactivate'
        expect(page).to have_content('Status: Inactive')
        click_on 'Activate'
        expect(page).to have_content('Status: Active')
      end
    end
  end

  describe 'submit issue' do
    context 'captcha is correct' do
      before { set_override_captcha true }

      scenario 'submits issue' do
        visit repository_public_path(repository.holder_name, repository.name)
        fill_in 'name', with: 'Joe Schmoe'
        fill_in 'email', with: 'joe.schmoe@gmail.com'
        fill_in 'details', with: 'Your code is broken!'
        fill_in 'captcha', with: 'asdfgh'
        click_on 'Submit'
        expect(page).to have_content('Thanks for submitting your report!')
      end
    end

    context 'captcha is incorrect' do
      before { set_override_captcha false }
      
      scenario 'prefills issue page and shows error' do
        visit repository_public_path(repository.holder_name, repository.name)
        fill_in 'name', with: 'Joe Schmoe'
        fill_in 'email', with: 'joe.schmoe@gmail.com'
        fill_in 'details', with: 'Your code is broken!'
        fill_in 'captcha', with: 'asdfgh'
        click_on 'Submit'
        expect(page).to have_content('Incorrect CAPTCHA; please retry!')
        expect(find_field('name').value).to eq('Joe Schmoe')
        expect(find_field('email').value).to eq('joe.schmoe@gmail.com')
        expect(find_field('details').value).to eq('Your code is broken!')
      end
    end
  end
end