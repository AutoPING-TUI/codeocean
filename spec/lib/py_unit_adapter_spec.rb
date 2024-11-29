# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PyUnitAdapter do
  let(:adapter) { described_class.new }

  describe '#parse_output' do

    #Initialize data for Testcase 1.1
    let(:count) {2}
    let(:failed) {0}
    let(:error_matches) {[]}
    let(:stderr) { File.read("spec/testcasedata/CorrectSolution.txt")}

    #Testcase 1.1
    it 'CorrectSolution' do
      expect(adapter.parse_output(stderr:)).to eq(count:, failed:, error_messages: error_matches)
    end

    #Initialize data for Testcase 1.2
    let(:count) {2}
    let(:failed) {1}
    let(:error_matches) {["test_odd: 0 is not true"]}
    let(:stderr) { File.read("spec/testcasedata/correctnumber.txt")}

    #Testcase 1.2
    it 'correct count/failed number' do
      expect(adapter.parse_output(stderr:)).to eq(count:, failed:, error_messages: error_matches)
    end

    #count and failed always 0 for following test cases (tests can't be executed)
    let(:count) {0}
    let(:failed) {0}
    #Initialize data for Testcase 1.3
    let(:error_matches) {["<span style=\"color:red\">**SyntaxError**</span>: invalid syntax in **file** /workspace/exercise.py **line 1**"]}
    let(:stderr) { File.read("spec/testcasedata/SyntaxErrorTest.txt")}

    #Testcase 1.3
    it 'SyntaxError' do
      expect(adapter.parse_output(stderr:)).to eq(count:, failed:, error_messages: error_matches)
    end

    #Initialize data for Testcase 1.4
    let(:error_matches) {["<span style=\"color:red\">**IndentationError**</span>: expected an indented block in **file** /workspace/exercise.py **line 2**"]}
    let(:stderr) { File.read("spec/testcasedata/IndentationErrorTest.txt")}

    #Testcase 1.4
    it 'IndentationError' do
      expect(adapter.parse_output(stderr:)).to eq(count:, failed:, error_messages: error_matches)
    end
    #TabError not tested at the moment because current codeocean version never raises it
  end
end
