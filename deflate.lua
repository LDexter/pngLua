local function make_outstate(outbs)
  local outstate = {}
  outstate.outbs = outbs
  outstate.window = {}
  outstate.window_pos = 1
  return outstate
end

local function output(outstate, byte)
  local window_pos = outstate.window_pos
  outstate.outbs(byte)
  outstate.window[window_pos] = byte
  outstate.window_pos = window_pos % 32768 + 1
end

local function memoize(f)
  local mt = {}
  local t = setmetatable({}, mt)
  function mt:__index(k)
      local v = f(k)
      t[k] = v
      return v
  end
  return t
end

local pow2 = memoize(function(n) return 2^n end)

local is_bitstream = setmetatable({}, {__mode='k'})

local function bytestream_from_string(s)
  local i = 1
  local o = {}

  function o:read()
      local by
      if i <= #s then
          by = s:byte(i)
          i = i + 1
      end
      return by
  end

  return o
end

local function bitstream_from_bytestream(bys)
  local buf_byte = 0
  local buf_nbit = 0
  local o = {}

  function o:nbits_left_in_byte()
      return buf_nbit
  end

  function o:read(nbits)
      nbits = nbits or 1
      while buf_nbit < nbits do
          local byte = bys:read()
          if not byte then return end
          buf_byte = buf_byte + lshift(byte, buf_nbit)
          buf_nbit = buf_nbit + 8
      end
      local bits
      if nbits == 0 then
          bits = 0
      elseif nbits == 32 then
          bits = buf_byte
          buf_byte = 0
      else
          bits = band(buf_byte, rshift(0xffffffff, 32 - nbits))
          buf_byte = rshift(buf_byte, nbits)
      end
      buf_nbit = buf_nbit - nbits
      return bits
  end
  
  is_bitstream[o] = true

  return o
end

local function HuffmanTable(init, is_full)
  local t = {}
  if is_full then
      for val,nbits in pairs(init) do
          if nbits ~= 0 then
              t[#t+1] = {val=val, nbits=nbits}
          end
      end
  else
      for i=1,#init-2,2 do
          local firstval, nbits, nextval = init[i], init[i+1], init[i+2]
          if nbits ~= 0 then
              for val=firstval,nextval-1 do
              t[#t+1] = {val=val, nbits=nbits}
              end
          end
      end
  end
  table_sort(t, function(a,b)
      return a.nbits == b.nbits and a.val < b.val or a.nbits < b.nbits
  end)

  local code = 1
  local nbits = 0
  for i,s in ipairs(t) do
      if s.nbits ~= nbits then
          code = code * pow2[s.nbits - nbits]
          nbits = s.nbits
      end
      s.code = code
      code = code + 1
  end

  local minbits = math.huge
  local look = {}
  for i,s in ipairs(t) do
      minbits = math.min(minbits, s.nbits)
      look[s.code] = s.val
  end

  local function msb(bits,nbits)
      local res = 0
      for i=1,nbits do
          res = lshift(res, 1) + band(bits, 1)
          bits = rshift(bits, 1)
      end
      return res
  end
  
  local tfirstcode = memoize(function(bits) return pow2[minbits] + msb(bits, minbits) end)

  function t:read(bs)
      local code = 1
      local nbits = 0
      while 1 do
          if nbits == 0 then
              code = tfirstcode[bs:read(minbits)]
              nbits = nbits + minbits
          else
              local b = bs:read()
              nbits = nbits + 1
              code = code * 2 + b
          end
          local val = look[code]
          if val then
              return val
          end
      end
  end

  return t
end

local function parse_huffmantables(bs)
  local hlit  = bs:read(5)
  local hdist = bs:read(5)
  local hclen = bs:read(4)

  local ncodelen_codes = hclen + 4
  local codelen_init = {}
  local codelen_vals = {16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15}
  for i=1,ncodelen_codes do
      local nbits = bs:read(3)
      local val = codelen_vals[i]
      codelen_init[val] = nbits
  end
  local codelentable = HuffmanTable(codelen_init, true)

  local function decode(ncodes)
      local init = {}
      local nbits
      local val = 0
      while val < ncodes do
          local codelen = codelentable:read(bs)
          local nrepeat
          if codelen <= 15 then
              nrepeat = 1
              nbits = codelen
          elseif codelen == 16 then
              nrepeat = 3 + bs:read(2)
          elseif codelen == 17 then
              nrepeat = 3 + bs:read(3)
              nbits = 0
          elseif codelen == 18 then
              nrepeat = 11 + bs:read(7)
              nbits = 0
          end
          for _=1,nrepeat do
              init[val] = nbits
              val = val + 1
          end
      end
      local huffmantable = HuffmanTable(init, true)
      return huffmantable
  end

  local nlit_codes = hlit + 257
  local ndist_codes = hdist + 1

  local littable = decode(nlit_codes)
  local disttable = decode(ndist_codes)

  return littable, disttable
end


local tdecode_len_base
local tdecode_len_nextrabits
local tdecode_dist_base
local tdecode_dist_nextrabits
local function parse_compressed_item(bs, outstate, littable, disttable)
  local val = littable:read(bs)
  if val < 256 then
      output(outstate, val)
  elseif val == 256 then
      return true
  else
      if not tdecode_len_base then
          local t = {[257]=3}
          local skip = 1
          for i=258,285,4 do
              for j=i,i+3 do t[j] = t[j-1] + skip end
              if i ~= 258 then skip = skip * 2 end
          end
          t[285] = 258
          tdecode_len_base = t
      end
      if not tdecode_len_nextrabits then
          local t = {}
          
          for i=257,285 do
              local j = math_max(i - 261, 0)
              t[i] = rshift(j, 2)
          end
          
          t[285] = 0
          tdecode_len_nextrabits = t
      end
      
      local len_base = tdecode_len_base[val]
      local nextrabits = tdecode_len_nextrabits[val]
      local extrabits = bs:read(nextrabits)
      local len = len_base + extrabits

      if not tdecode_dist_base then
          local t = {[0]=1}
          local skip = 1
          for i=1,29,2 do
              for j=i,i+1 do t[j] = t[j-1] + skip end
              if i ~= 1 then skip = skip * 2 end
          end
          tdecode_dist_base = t
      end
      if not tdecode_dist_nextrabits then
          local t = {}
          for i=0,29 do
              local j = math_max(i - 2, 0)
              t[i] = rshift(j, 1)
          end

          tdecode_dist_nextrabits = t
      end
      local dist_val = disttable:read(bs)
      local dist_base = tdecode_dist_base[dist_val]
      local dist_nextrabits = tdecode_dist_nextrabits[dist_val]
      local dist_extrabits = bs:read(dist_nextrabits)
      local dist = dist_base + dist_extrabits
      for i=1,len do
          local pos = (outstate.window_pos - 1 - dist) % 32768 + 1
          output(outstate,outstate.window[pos])
      end
  end
  return false
end


local function parse_block(bs, outstate)
  local bfinal = bs:read(1)
  local btype  = bs:read(2)

  local BTYPE_NO_COMPRESSION = 0
  local BTYPE_FIXED_HUFFMAN = 1
  local BTYPE_DYNAMIC_HUFFMAN = 2

  if btype == BTYPE_NO_COMPRESSION then
      bs:read(bs:nbits_left_in_byte())
      local len = bs:read(16)
      bs:read(16)

      for _=1,len do
          output(outstate, bs:read(8))
      end
  elseif btype == BTYPE_FIXED_HUFFMAN or btype == BTYPE_DYNAMIC_HUFFMAN then
      local littable, disttable
      if btype == BTYPE_DYNAMIC_HUFFMAN then
          littable, disttable = parse_huffmantables(bs)
      else
          littable  = HuffmanTable {0,8, 144,9, 256,7, 280,8, 288,nil}
          disttable = HuffmanTable {0,5, 32,nil}
      end

      repeat
          local is_done = parse_compressed_item(bs, outstate, littable, disttable)
      until is_done
  end

  return bfinal ~= 0
end


local function inflate(t)
  local bs = is_bitstream[t.input] and t.input or bitstream_from_bytestream(bytestream_from_string(t.input))
  local outstate = make_outstate(t.output)

  repeat
      local is_final = parse_block(bs, outstate)
  until is_final
end

local function adler32(byte, crc)
  local s1 = crc % 65536
  local s2 = (crc - s1) / 65536
  s1 = (s1 + byte) % 65521
  s2 = (s2 + s1) % 65521
  return s2*65536 + s1
end

function lib.inflate_zlib(t)
  local bs = bitstream_from_bytestream(bytestream_from_string(t.input))
  local disable_crc = t.disable_crc
  if disable_crc == nil then disable_crc = false end

  bs:read(13)
  if bs:read(1) == 1 then bs:read(32) end
  bs:read(2)
  
  local data_adler32 = 1
  
  inflate{input=bs, output=
      disable_crc and t.output or function(byte)
          data_adler32 = adler32(byte, data_adler32)
          t.output(byte)
      end
  }

  bs:read(bs:nbits_left_in_byte())
end