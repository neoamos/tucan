defmodule AppWeb.ViewHelpers do
  def markdown(md) do
    if md do
      try do
      md
      |> Earmark.as_html!(%Earmark.Options{gfm: true, breaks: true, smartypants: false, compact_output: true})
      rescue
        _ -> md
      end
    else
      ""
    end
  end

  def time_since(datetime) do
    case Timex.lformat(datetime, "{relative}", Gettext.get_locale(), :relative) do
      {:ok, time_str} -> time_str
      _ -> ""
    end
  end

  def description_sanitize(html) do
    sanitize(html, AppWeb.Scrubber.Description)
  end

  def comment_sanitize(html) do
    sanitize(html, AppWeb.Scrubber.Comment)
  end

  def md_sanitize(html) do
    sanitize(html, AppWeb.Scrubber.Markdown)
  end

  def sanitize(html, scrubber) do
    if html do
      html = html
      |> HtmlSanitizeEx.Scrubber.scrub(scrubber)
    else
      ""
    end
  end

  def user(user, opts \\ %{}) do
    relays = if Ecto.assoc_loaded?(user.relays) do
      Enum.filter(user.relays, fn ur -> ur.profile==true end)
      |> Enum.map(fn ur ->
        %{
          url: ur.relay.url,
          read: ur.read,
          write: ur.write,
          global: ur.global
        }
      end)
    end
    %{
      id: user.id,
      pubkey: Base.encode16(user.pubkey, case: :lower),
      name: user.name,
      username: user.username,
      about: user.about,
      picture: user.picture,
      banner: user.banner,
      nip5: (if user.nip5_verified, do: user.nip5_identifier),
      lud06: user.lud06,
      lud16: user.lud16,
      follower_count: user.follower_count,
      following_count: user.following_count,
      relays: relays,
      followed: opts[:followed]
    }
  end

  def post(post, opts \\ %{}) do
    content = post.content
    # |> ViewHelpers.markdown()
    # |> ViewHelpers.md_sanitize()

    user_mentions = if Ecto.assoc_loaded?(post.user_mentions) do
      Map.new(post.user_mentions, fn m ->
        {m.position, %{
          t: "u",
          name: m.mentioned.name,
          nip5: (if m.mentioned.nip5_verified, do: m.mentioned.nip5_identifier),
          pubkey: Base.encode16(m.mentioned.pubkey, case: :lower)
        }}
      end)
    end

    post_mentions = if Ecto.assoc_loaded?(post.post_mentions) do
      Map.new(post.post_mentions, fn p ->
        {p.position, %{
          t: "p",
          event_id: Base.encode16(p.mentioned.event_id, case: :lower)
        }}
      end)
    end

    root_reply = if Ecto.assoc_loaded?(post.root_reply) and !!post.root_reply do
      received_by = if Ecto.assoc_loaded?(post.root_reply.received_by) do
        relay = Enum.at(post.root_reply.received_by, 0)
        if relay, do: relay.url
      end
      %{
        event_id: Base.encode16(post.root_reply.event_id, case: :lower),
        pubkey: Base.encode16(post.root_reply.user.pubkey, case: :lower),
        received_by: received_by
      }
    end

    received_by = if Ecto.assoc_loaded?(post.received_by) do
      relay = Enum.at(post.received_by, 0)
      if relay, do: relay.url
    end

    %{
      id: post.id,
      event_id: Base.encode16(post.event_id, case: :lower),
      user: %{
        pubkey: Base.encode16(post.user.pubkey, case: :lower),
        name: post.user.name,
        picture: post.user.picture,
        nip5: (if post.user.nip5_verified, do: post.user.nip5_identifier)
      },
      content: (content || ""),
      received_at: post.inserted_at,
      created_at: post.created_at,
      like_count: post.like_count,
      reply_count: post.reply_count,
      mentions: (if (!!user_mentions and !!post_mentions), do: Map.merge(user_mentions, post_mentions)),
      root_reply: root_reply,
      received_by: received_by,
      liked: opts[:liked]
    }
  end
end
