# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Game do
  it 'has a valid factory' do
    expect(build(:game)).to be_valid
  end
end
