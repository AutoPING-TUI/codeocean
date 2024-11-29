# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JunitAdapter do
  let(:adapter) { described_class.new }


  describe '#parse_output' do
    
    context 'CorrectSolution' do
      #Initialize data for Testcase 2.1
      let(:count) { 42 }
      let(:stdout) { "OK (#{count} tests)" }
      
      #Testcase 2.1
      it 'returns the correct numbers' do
        expect(adapter.parse_output(stdout:)).to eq(count:, passed: count)
      end
    end

    context 'with assertionerrors' do
      #Initialize data for Testcase 2.2
      let(:count) { 42 }
      let(:failed) { 25 }
      let(:stdout) { "FAILURES!!!\nTests run: #{count},  Failures: #{failed}" }
      let(:stderr) {""}
      let(:error_matches) { [] }


      #Testcase 2.2
      it 'returns the correct numbers' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end
    
    #From here on compilation errors only (count = failed = 0)
    context 'unclosed string literal' do

      let(:count) {0}
      let(:failed) {0}
      let(:stdout) {""}

      #Initialize data for Testcase 2.3
      let(:stderr) { File.read("spec/testcasedatajava/UnclosedStringLiteralTest.txt")}
      let(:error_matches) {["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 6** occured **unclosed string literal** at String s=\"test; "]}
      #["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 6** occured **unclosed string literal** at String s=\"test; "]

      #Testcase 2.3
      it 'unclosed string literal' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end

    context 'illegal start of expression' do
      let(:count) {0}
      let(:failed) {0}
      let(:stdout) {""}

      #Initialize data for Testcase 2.4
      let(:stderr) { File.read("spec/testcasedatajava/IllegalStartOfExpressionTest.txt")}
      let(:error_matches) {["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 10** occured **illegal start of expression** at private int i=0; "]}

      #Testcase 2.4
      it 'illegal start of expression' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end

    context 'variable might not have been initialized' do
      let(:count) {0}
      let(:failed) {0}
      let(:stdout) {""}

      #Initialize data for Testcase 2.5
      let(:stderr) { File.read("spec/testcasedatajava/VariableMightNotHaveBeenInitializedTest.txt")}
      let(:error_matches) { ["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 11** occured **variable i might not have been initialized** at i=i+1; "]}

      #Testcase 2.5
      it 'variable .. might not have been initialized' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end

    context 'not a statement' do
      let(:count) {0}
      let(:failed) {0}
      let(:stdout) {""}

      #Initialize data for Testcase 2.6
      let(:stderr) { File.read("spec/testcasedatajava/NotAStatementTest.txt")}
      let(:error_matches) {["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 12** occured **not a statement** at \"test\"; "]}

      #Testcase 2.6
      it 'not a statement' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end

    context 'unexpected type' do
      let(:count) {0}
      let(:failed) {0}
      let(:stdout) {""}

      #Initialize data for Testcase 2.7
      let(:stderr) { File.read("spec/testcasedatajava/UnexpectedTypeTest.txt")}
      let(:error_matches) {["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 11** occured **unexpected type** at if(1=0){ "]}

      #Testcase 2.7
      it 'unexpected type' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end

    context 'something expected' do
      let(:count) {0}
      let(:failed) {0}
      let(:stdout) {""}

      #Initialize data for Testcase 2.8
      let(:stderr) { File.read("spec/testcasedatajava/SomethingExpectedTest.txt")}
      let(:error_matches) {["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 12** occured **';' expected** at return 1/power(base,-exponent) "]}

      #Testcase 2.8
      it '... expected' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end

    context 'bad operand types' do
      let(:count) {0}
      let(:failed) {0}
      let(:stdout) {""}

      #Initialize data for Testcase 2.9
      let(:stderr) { File.read("spec/testcasedatajava/BadOperandTypesTest.txt")}
      let(:error_matches) {["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 12** occured **bad operand types for binary operator '+'** at System.out.println(a+b); "]}

      #Testcase 2.9
      it 'bad operand types ...' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end

    context 'incompatible types' do
      let(:count) {0}
      let(:failed) {0}
      let(:stdout) {""}

      #Initialize data for Testcase 2.10
      let(:stderr) { File.read("spec/testcasedatajava/IncompatibleTypesTest.txt")}
      let(:error_matches) {["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 12** occured **incompatible types: String cannot be converted to int** at power(a,s); "]}

      #Testcase 2.10
      it 'incompatible types: ...' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end

    context 'missing return' do
      let(:count) {0}
      let(:failed) {0}
      let(:stdout) {""}

      #Initialize data for Testcase 2.11
      let(:stderr) { File.read("spec/testcasedatajava/MissingReturnTest.txt")}
      let(:error_matches) {["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 19** occured **missing return statement** at } "]}

      #Testcase 2.11
      it 'missing return ..' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end

    context 'invalid method declaration' do
      let(:count) {0}
      let(:failed) {0}
      let(:stdout) {""}

      #Initialize data for Testcase 2.12
      let(:stderr) { File.read("spec/testcasedatajava/InvalidMethodDeclarationTest.txt")}
      let(:error_matches) {["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 19** occured **invalid method declaration; return type required** at public static add(int a,int b){ "]}
 
      #Testcase 2.12
      it 'invalid method declaration ...' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end

    context 'unreachable statement' do
      let(:count) {0}
      let(:failed) {0}
      let(:stdout) {""}

      #Initialize data for Testcase 2.13
      let(:stderr) { File.read("spec/testcasedatajava/UnreachableStatementTest.txt")}
      let(:error_matches) {["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 12** occured **unreachable statement** at System.out.println(\"test\"); "]}
 
      #Testcase 2.13
      it 'unreachable statement' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end

    context 'cannot be referenced from a static context' do
      let(:count) {0}
      let(:failed) {0}
      let(:stdout) {""}

      #Initialize data for Testcase 2.14
      let(:stderr) { File.read("spec/testcasedatajava/CannotBeReferencedFromAStaticContextTest.txt")}
      let(:error_matches) {["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 6** occured **non-static variable field cannot be referenced from a static context** at field = parm; "]}
 
      #Testcase 2.14
      it '... cannot be referenced from a static context' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end

    context 'reached end of file while parsing' do
      let(:count) {0}
      let(:failed) {0}
      let(:stdout) {""}

      #Initialize data for Testcase 2.15
      let(:stderr) { File.read("spec/testcasedatajava/ReachedEndOfFileWhileParsingTest.txt")}
      let(:error_matches) {["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 22** occured **reached end of file while parsing** at } "]}
 
      #Testcase 2.15
      it 'reached end of file while parsing' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end

    context 'cannot be applied to' do
      let(:count) {0}
      let(:failed) {0}
      let(:stdout) {""}

      #Initialize data for Testcase 2.16
      let(:stderr) { File.read("spec/testcasedatajava/CannotBeAppliedToTest.txt")}
      let(:error_matches) {["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 12** occured **method power in class RecursiveMath cannot be applied to given types;** at return 1/power();\n required: int,int\n found: no arguments "]}

      #Testcase 2.16
      it '... cannot be applied to ...' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end

    context 'cannot find symbol' do
      let(:count) {0}
      let(:failed) {0}
      let(:stdout) {""}

      #Initialize data for Testcase 2.17
      let(:stderr) { File.read("spec/testcasedatajava/CannotFindSymbolTest.txt")}
      let(:error_matches) {["<span style=\"color:red\">**Compilation Error**</span> in **file** ./org/example/RecursiveMath **line 11** occured **cannot find symbol** at System.out.println(i);\n symbol:   variable i\n location: class RecursiveMath "]}

      #Testcase 2.17
      it 'cannot find symbol...' do
        expect(adapter.parse_output(stdout: stdout, stderr: stderr)).to eq(count:, failed:, error_messages: error_matches)
      end
    end
  end

end