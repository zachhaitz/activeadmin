module Arbre
  module HTML

    class Element
      include ::Arbre::HTML
      include ::Arbre::HTML::BuilderMethods

      attr_accessor :parent
      attr_reader :children

      def self.builder_method(method_name)
        ::Arbre::HTML::BuilderMethods.class_eval <<-EOF, __FILE__, __LINE__
          def #{method_name}(*args, &block)
            insert_tag #{self.name}, *args, &block
          end
        EOF
      end

      def initialize(assigns = {}, helpers = nil)
        @_assigns, @_helpers = assigns, helpers
        @children = Collection.new
      end

      def assigns
        @_assigns
      end

      def helpers
        @_helpers
      end

      def tag_name
        @tag_name ||= self.class.name.demodulize.downcase
      end

      def build(*args, &block)
        # Render the block passing ourselves in
        insert_text_node_if_string(block.call(self)) if block
      end

      def add_child(child)
        return unless child

        if child.is_a?(String)
          child = TextNode.from_string(child)
        end

        if child.respond_to?(:parent)
          # Remove the child
          child.parent.remove_child(child) if child.parent
          # Set ourselves as the parent
          child.parent = self
        end

        @children << child
      end

      def remove_child(child)
        child.parent = nil if child.respond_to?(:parent=)
        @children.delete(child)
      end

      def <<(child)
        add_child(child)
      end

      def parent=(parent)
        @parent = parent
      end

      def parent?
        !@parent.nil?
      end

      def document
        parent.document if parent?
      end

      def content=(string_contents)
        clear_children!
        add_child(ERB::Util.html_escape(string_contents)) if string_contents
      end

      def get_elements_by_tag_name(tag_name)
        elements = Collection.new
        children.each do |child|
          elements << child if child.tag_name == tag_name
          elements.concat(child.get_elements_by_tag_name(tag_name))
        end
        elements
      end
      alias_method :find_by_tag, :get_elements_by_tag_name

      def content
        children.to_html
      end

      def html_safe
        to_html
      end

      def each(&block)
        [to_html].each(&block)
      end

      def to_s
        to_html
      end

      def to_html
        content
      end

      private

      # Resets the Elements children
      def clear_children!
        @children.clear
      end
    end

  end
end
