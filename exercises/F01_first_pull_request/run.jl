module F01FirstPullRequest

export main, student_greeting

"""
    student_greeting(name::AbstractString) -> String

`name`の前後の空白を除き、`"Hello, <name>!"`を返す。
空の名前は無効とする。F01ではTODOの未実装エラーを戻り値を求める処理へ置き換える。
"""
function student_greeting(name::AbstractString)::String
    normalized_name = strip(name)
    isempty(normalized_name) && throw(ArgumentError("名前を空にはできません"))

    return "Hello, $(normalized_name)!"
end

function main(name::AbstractString="student"; io=stdout)
    message = student_greeting(name)
    println(io, message)
    message
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    name = isempty(ARGS) ? "student" : only(ARGS)
    F01FirstPullRequest.main(name)
end
