# -*- encoding: utf-8 -*-
module Stomper
  module FrameIO
    FRAME_TERMINATOR = "\000".chr
    
    def write_frame(frame)
      if frame.command
        write [frame.command, "\n", serialize_headers(frame),
          "\n", frame.body, FRAME_TERMINATOR].compact.join
      else
        write "\n"
      end
    end
    
    def read_frame
      command = gets.chomp
      frame = Stomper::Frame.new
      unless command.empty?
        frame.command = command
        header_line = gets_encoded.chomp
        while header_line.length > 0
          key, val = header_line.split(':').map { |v| unescape_header(v) }
          frame.headers.append(key, val)
          header_line = gets_encoded.chomp
        end
        body = nil
        if frame['content-length'] && (len = frame['content-length'].to_i) > 0
          body = read len
          raise "malformed frame" if get_body_byte
        else
          while (c = get_body_byte)
            body ||= ""
            body << c
          end
        end
        frame.body = encode_body(body, frame['content-type'])
      end
      frame
    end
    
    private
    def encode_body(body, ct_header)
      if ct_header
        charset = $1 if ct_header.match /\;\s*charset=\"?([\w\-]+)\"?/i
        charset ||= (ct_header =~ /^text\// && 'UTF-8')
        if charset
          body.force_encoding(charset)
        end
      else
        body.force_encoding('US-ASCII')
      end
      body
    end
    
    def escape_header(hdr)
      str = hdr && hdr.to_s || ''
      str.gsub(/[\\\n:]/, '\\' => '\\\\', ':' => '\\c', "\n" => "\\n")
    end
    
    def unescape_header(hdr)
      hdr.gsub(/(\\[\\cn])/, '\\c' => ':', '\\n' => "\n", '\\\\' => '\\')
    end
    
    def serialize_headers(frame)
      serialized = frame.headers.inject('') do |head_str, (k, v)|
        k = escape_header(k)
        next if ['content-type', 'content-length'].include?(k) || k.empty?
        v = escape_header(v)
        head_str << "#{k}:#{v}\n"
        head_str
      end
      if frame.content_type_and_charset
        serialized << "content-type:#{frame.content_type_and_charset}\n"
      end
      if frame.body
        serialized << "content-length:#{frame.body.bytesize}\n"
      end
      serialized
    end
    
    def get_body_byte
      c = getc
      c == FRAME_TERMINATOR ? nil : c
    end
    
    def gets_encoded
      line = gets
      line.force_encoding("UTF-8")
      line
    end
  end
end
