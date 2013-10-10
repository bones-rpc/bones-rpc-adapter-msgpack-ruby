# encoding: utf-8
require 'bones/rpc/adapter'
require 'msgpack'

module Bones
  module RPC
    module Adapter
      module Msgpack

        @adapter_name = :msgpack

        def pack(message, buffer="")
          buffer << ::MessagePack.pack(message)
        end

        def unpack(buffer)
          ::MessagePack.unpack(buffer)
        end

        def unpack_stream(stream)
          buffer = StringIO.new(stream)
          ::MessagePack::Unpacker.new(buffer).read
        end

        def read(unpacker)
          (unpacker.adapter_unpacker ||= ::MessagePack::Unpacker.new(unpacker.buffer)).read
        end

        def unpacker(data)
          Unpacker.new(StringIO.new(data))
        end

        def parser(data)
          Adapter::Parser.new(self, data)
        end

        if !!(RUBY_PLATFORM =~ /java/)
          require 'bones/rpc/adapter/msgpack/ruby'
          Unpacker = Bones::RPC::Adapter::Msgpack::Ruby::Decoder

          def unpacker_pos(parser)
            parser.unpacker.buffer.pos
          end

          def unpacker_seek(parser, n)
            parser.unpacker.buffer.seek(n)
            return n
          end
        else
          Unpacker = ::MessagePack::Unpacker

          def unpacker_pos(parser)
            size = parser.unpacker.buffer.size
            pos  = parser.unpacker.buffer.io.pos
            (pos > size) ? (pos - size) : 0
          end

          def unpacker_seek(parser, n)
            pos = unpacker_pos(parser)
            parser.unpacker.buffer.skip(n - pos) if pos < n
            return pos
          end
        end

        Adapter.register self
      end
    end
  end
end
