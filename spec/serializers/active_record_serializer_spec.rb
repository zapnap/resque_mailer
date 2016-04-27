require 'spec_helper'

describe Resque::Mailer::Serializers::ActiveRecordSerializer do
  module ActiveRecord; end
  class ActiveRecord::Base < Struct.new(:id); end # mock
  class FakeModel < ActiveRecord::Base; end

  let(:model) { FakeModel.new(7) }

  describe '.serialize' do
    it 'serializes active record model' do
      expect(subject.serialize(7, 'seven', model))
        .to eq [7, 'seven', { 'class_name' => 'FakeModel', 'id' => model.id }]
    end
  end

  describe '.deserialize' do
    before do
      allow(FakeModel).to receive(:find) { model }
    end

    it 'serializes active record model' do
      expect(subject.deserialize([7, 'seven', { 'class_name' => 'FakeModel', 'id' => model.id }]))
        .to eq [7, 'seven', model]
    end
  end
end
