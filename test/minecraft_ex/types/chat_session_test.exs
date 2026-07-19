defmodule MinecraftEx.Types.ChatSessionTest do
  use ExUnit.Case, async: true

  alias MinecraftEx.Types.ChatSession

  ## Tests

  test "decodes and encodes the 26.2 chat session data" do
    data =
      <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 123::signed-64, 2, 16, 17, 3, 32,
        33, 34>>

    assert {%ChatSession{} = chat_session, <<>>} = ChatSession.decode(data)

    assert chat_session.session_id == "00010203-0405-0607-0809-0a0b0c0d0e0f"
    assert chat_session.expires_at == 123
    assert chat_session.public_key == <<16, 17>>
    assert chat_session.key_signature == <<32, 33, 34>>
    assert ChatSession.encode(chat_session) == data
  end
end
