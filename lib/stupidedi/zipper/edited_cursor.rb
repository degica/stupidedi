module Stupidedi
  module Zipper

    class EditedCursor < AbstractCursor

      # @return [#leaf?, #children, #copy]
      attr_reader :node

      # @return [Hole]
      attr_reader :path

      # @private
      # @return [AbstractCursor]
      attr_reader :parent

      def initialize(node, path, parent)
        @node, @path, @parent =
          node, path, parent
      end

      #########################################################################
      # @group Query Methods

      def leaf?
        @node.leaf? or @node.children.empty?
      end

      def root?
        false
      end

      # @endgroup
      #########################################################################

      #########################################################################
      # @group Traversal Methods

      # @return [MemoizedCursor]
      def down
        if leaf?
          raise Exceptions::ZipperError
        end

        head, *tail = @node.children

        MemoizedCursor.new(head,
          Hole.new([], @path, tail), self)
      end

      # @return [AbstractCursor]
      def up
        node =
          @parent.node.copy(:children => 
            @path.left.reverse.concat(@node.cons(@path.right)))

        if parent.root?
          RootCursor.new(node)
        else
          EditedCursor.new(node, @path.parent, @parent.parent)
        end
      end

      # @return [EditedCursor]
      def next
        if last?
          raise Exceptions::ZipperError
        end

        head, *tail = @path.right

        EditedCursor.new(head,
          Hole.new(@node.cons(@path.left), @path.parent, tail), @parent)
      end
      
      # @return [EditedCursor]
      def prev
        if first?
          raise Exceptions::ZipperError
        end

        head, *tail = @path.left

        EditedCursor.new(head,
          Hole.new(tail, @path.parent, @node.cons(@path.right)), @parent)
      end

      # @endgroup
      #########################################################################

      #########################################################################
      # @group Editing Methods

      # @return [EditedCursor]
      def append(node)
        EditedCursor.new(node,
          Hole.new(@node.cons(@path.left), @path.parent, @path.right), @parent)
      end

      # @return [EditedCursor]
      def prepend
        EditedCursor.new(node,
          Hole.new(@path.left, @path.parent, @node.cons(@path.right)), @parent)
      end

      # @return [EditedCursor]
      def replace(node)
        EditedCursor.new(node, @path, @parent)
      end

      # @return [EditedCursor]
      def delete
        if not last?
          # Move to `next`
          head, *tail = @path.right

          EditedCursor.new(head,
            Hole.new(@path.left, @path.parent, tail), @parent)
        elsif not first?
          # Move to `prev`
          head, *tail = @path.left

          EditedCursor.new(head,
            Hole.new(tail, @path.parent, @path.right), @parent)
        else
          # Deleting the only child
          parent =
            @parent.node.copy(:children => 
              @path.left.reverse.concat(@path.right))

          EditedCursor.new(parent, @path.parent, @parent.parent)
        end
      end

      # @endgroup
      #########################################################################
    end

  end
end
