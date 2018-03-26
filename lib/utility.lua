function is_in(value,tbl)
  for _, item in tbl do
    if item == value then
      return true
    end
  end
  return false
end

function print_table(tbl, prefix)
  print('********', prefix, '********')
  for _, item in pairs(tbl) do
    print(item.id)
  end
  print('========', prefix, '========')
end
