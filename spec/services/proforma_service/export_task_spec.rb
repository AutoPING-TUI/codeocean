# frozen_string_literal: true

require 'rails_helper'

describe ProformaService::ExportTask do
  describe '.new' do
    subject(:export_task) { described_class.new(exercise: exercise) }

    let(:exercise) { FactoryBot.build(:dummy) }

    it 'assigns exercise' do
      expect(export_task.instance_variable_get(:@exercise)).to be exercise
    end

    context 'without exercise' do
      subject(:export_task) { described_class.new }

      it 'assigns exercise' do
        expect(export_task.instance_variable_get(:@exercise)).to be nil
      end
    end
  end

  describe '#execute' do
    subject(:export_task) { described_class.call(exercise: exercise) }

    let(:task) { Proforma::Task.new }
    let(:exercise) { FactoryBot.build(:dummy) }
    let(:exporter) { instance_double('Proforma::Exporter', perform: 'zip') }

    before do
      allow(ProformaService::ConvertExerciseToTask).to receive(:call).with(exercise: exercise).and_return(task)
      allow(Proforma::Exporter).to receive(:new).with(task: task, custom_namespaces: [{prefix: 'CodeOcean', uri: 'codeocean.openhpi.de'}]).and_return(exporter)
    end

    it do
      export_task
      expect(exporter).to have_received(:perform)
    end
    # TODO more tests?!
  end
end
