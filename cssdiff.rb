
# Normalised CSS rule-set diff: order-insensitive, whitespace/comment-insensitive.
# usage: ruby cssdiff.rb baseline.css current.css

def rules(path)
  css = File.read(path, encoding: 'bom|utf-8')
  css = css.gsub(%r{/\*.*?\*/}m, ' ')          # comments
  out, ctx, buf, depth = Hash.new(0), [], +'', 0
  css.each_char do |c|
    case c
    when '{'
      depth += 1
      if depth == 1 && buf.strip.start_with?('@') && buf !~ /@(font-face|page)/
        ctx.push(buf.strip.squeeze(' ')); buf = +''
      elsif depth >= 1 && buf.strip.start_with?('@') && buf !~ /@(font-face|page)/
        ctx.push(buf.strip.squeeze(' ')); buf = +''
      else
        buf << c
      end
    when '}'
      depth -= 1
      if buf.include?('{')
        sel, decl = buf.split('{', 2)
        key = [ctx.join(' | '), sel.strip.squeeze(' ').gsub(/\s*,\s*/, ','),
               decl.strip.squeeze(' ').split(';').map(&:strip).reject(&:empty?).join(';')].join(' >> ')
        out[key] += 1
        buf = +''
      else
        ctx.pop
        buf = +''
      end
    else
      buf << (c =~ /\s/ ? ' ' : c)
    end
  end
  out
end

a, b = rules(ARGV[0]), rules(ARGV[1])
only_a = a.reject { |k, v| b[k] == v }
only_b = b.reject { |k, v| a[k] == v }

puts "baseline rules: #{a.values.sum} (#{a.size} distinct)"
puts "current  rules: #{b.values.sum} (#{b.size} distinct)"
puts "=" * 70
if only_a.empty? && only_b.empty?
  puts "IDENTICAL rule sets (modulo order, whitespace, comments)"
else
  puts "MISSING in current (#{only_a.size}):"
  only_a.each { |k, v| puts "  [#{v}x#{b[k]}] #{k[0, 300]}" }
  puts
  puts "EXTRA in current (#{only_b.size}):"
  only_b.each { |k, v| puts "  [#{v}x#{a[k]}] #{k[0, 300]}" }
end
