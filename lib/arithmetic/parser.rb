module Arithmetic
  class Parser

    def self.is_a_number?(str)
      str.respond_to?(:to_str) && !!str.to_str.match(/^[\d\.]+$/)
    end

    def initialize(exp)
      @expression = exp
      @node_stack = []
    end

    def parse
      tokens = Tokenizer.new.tokenize(@expression)
      op_stack = []
     
      tokens.each do |token|
        if token.is_a? Operator
          # clear stack of higher priority operators
          while (!op_stack.empty? &&
                 op_stack.last != "(" &&
                 op_stack.last.priority >= token.priority)
            push_operator(op_stack.pop)
          end
     
          op_stack.push(token)
        elsif token == "("
          op_stack.push(token)
        elsif token == ")"
          while op_stack.last != "("
            push_operator(op_stack.pop)
          end
     
          # throw away the '('
          op_stack.pop
        else
          push_operand(token)
        end
      end
     
      until op_stack.empty?
        push_operator(op_stack.pop)
      end
     
      parsed_expression = @node_stack.pop
      raise InvalidExpression.new(@expression) unless @node_stack.empty?
      parsed_expression
    end

    private

    def push_operand(operand)
      raise InvalidExpression.new(@expression) unless Arithmetic::Parser.is_a_number?(operand)
      @node_stack.push(OperandNode.new(operand))
    end

    def push_operator(operator)
      raise InvalidExpression.new(@expression) unless operator.is_a?(Operator)

      operands = []
      operator.arity.times do
        operands.unshift(@node_stack.pop)
      end
      raise InvalidExpression.new(@expression) if operands.any?(&:nil?)

      @node_stack.push(OperatorNode.new(operator, operands))
    end
  end

  class Tokenizer
    def tokenize(exp)
      tokens = exp
        .gsub('*', ' * ')
        .gsub('/', ' / ')
        .gsub('+', ' + ')
        .gsub('-', ' - ')
        .gsub('(', ' ( ')
        .gsub(')', ' ) ')
        .split(' ')
      tokens = parse_operators(tokens)
      replace_unary_minus(tokens)
    end

    private

    def parse_operators(tokens)
      tokens.map do |token|
        Operators.get(token) || token
      end
    end

    def replace_unary_minus(tokens)
      new_tokens = []
      tokens.each_with_index do |current_token, i|
        previous_token = tokens[i-1]
        if current_token == Operators::MINUS && (i == 0 || previous_token.is_a?(Operator))
          new_tokens << Operators::UNARY_MINUS
        else
          new_tokens << current_token
        end
      end
      new_tokens
    end
  end

  class InvalidExpression < Exception
  end
end
