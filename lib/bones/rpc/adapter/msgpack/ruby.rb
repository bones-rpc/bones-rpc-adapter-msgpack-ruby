# encoding: utf-8

module Bones
  module RPC
    module Adapter
      module Msgpack
        module Ruby
          def self.unpack(bytes)
            Decoder.new(bytes).next
          end

          class Decoder
            attr_reader :buffer

            def initialize(buffer)
              @buffer = ::Bones::RPC::Parser::Buffer.new(buffer)
            end

            def next
              buffer.transaction do
                consume_next
              end
            rescue TypeError
              raise EOFError
            end
            alias :read :next

            private

            DECODINGS = []
            DECODINGS[0xc0] = lambda { |d| nil }
            DECODINGS[0xc2] = lambda { |d| false }
            DECODINGS[0xc3] = lambda { |d| true }
            DECODINGS[0xc4] = lambda { |d| d.consume_string(d.consume_byte, Encoding::BINARY) }
            DECODINGS[0xc5] = lambda { |d| d.consume_string(d.consume_int16, Encoding::BINARY) }
            DECODINGS[0xc6] = lambda { |d| d.consume_string(d.consume_int32, Encoding::BINARY) }
            DECODINGS[0xca] = lambda { |d| d.consume_float }
            DECODINGS[0xcb] = lambda { |d| d.consume_double }
            DECODINGS[0xcc] = lambda { |d| d.consume_byte }
            DECODINGS[0xcd] = lambda { |d| d.consume_int16 }
            DECODINGS[0xce] = lambda { |d| d.consume_int32 }
            DECODINGS[0xcf] = lambda { |d| d.consume_int64 }
            DECODINGS[0xd0] = lambda { |d| d.consume_byte - 0x100 }
            DECODINGS[0xd1] = lambda { |d| d.consume_int16 - 0x10000 }
            DECODINGS[0xd2] = lambda { |d| d.consume_int32 - 0x100000000 }
            DECODINGS[0xd3] = lambda { |d| d.consume_int64 - 0x10000000000000000 }
            DECODINGS[0xd9] = lambda { |d| d.consume_string(d.consume_byte) }
            DECODINGS[0xda] = lambda { |d| d.consume_string(d.consume_int16) }
            DECODINGS[0xdb] = lambda { |d| d.consume_string(d.consume_int32) }
            DECODINGS[0xdc] = lambda { |d| d.consume_array(d.consume_int16) }
            DECODINGS[0xdd] = lambda { |d| d.consume_array(d.consume_int32) }
            DECODINGS[0xde] = lambda { |d| Hash[*d.consume_array(d.consume_int16 * 2)] }
            DECODINGS[0xdf] = lambda { |d| Hash[*d.consume_array(d.consume_int32 * 2)] }

            FLOAT_FMT = 'g'.freeze
            DOUBLE_FMT = 'G'.freeze

            public

            def consume_byte
              buffer.getbyte
            end

            def consume_int16
              (consume_byte << 8) | consume_byte
            end

            def consume_int32
              (consume_byte << 24) | (consume_byte << 16) | (consume_byte << 8) | consume_byte
            end

            def consume_int64
              n  = (consume_byte << 56)
              n |= (consume_byte << 48)
              n |= (consume_byte << 40)
              n |= (consume_byte << 32)
              n |= (consume_byte << 24)
              n |= (consume_byte << 16)
              n |= (consume_byte << 8)
              n |=  consume_byte
              n
            end

            def consume_float
              f, = buffer.read(4).unpack(FLOAT_FMT)
              f
            end

            def consume_double
              d, = buffer.read(8).unpack(DOUBLE_FMT)
              d
            end

            def consume_string(size, encoding=Encoding::UTF_8)
              s = buffer.read(size)
              s.force_encoding(encoding)
              s
            end

            def consume_array(size)
              Array.new(size) { consume_next }
            end

            def consume_next
              b = consume_byte
              if (method = DECODINGS[b])
                method.call(self)
              elsif b <= 0b01111111
                b
              elsif b & 0b11100000 == 0b11100000
                b - 0x100
              elsif b & 0b11100000 == 0b10100000
                size = b & 0b00011111
                consume_string(size)
              elsif b & 0b11110000 == 0b10010000
                size = b & 0b00001111
                consume_array(size)
              elsif b & 0b11110000 == 0b10000000
                size = b & 0b00001111
                Hash[*consume_array(size * 2)]
              end
            end
          end
        end
      end
    end
  end
end
