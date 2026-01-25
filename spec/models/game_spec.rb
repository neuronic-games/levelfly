# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Game do
  it 'has a valid factory' do
    expect(build(:game)).to be_valid
    expect { create(:game) }.not_to raise_error
  end
end
