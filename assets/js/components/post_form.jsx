import React, {useState, useEffect, useRef} from "react"
import ProfilePicture from "./profile_picture";

import { connect, useSelector } from 'react-redux'
import { post_path, profile_path } from "../url_helpers";
import { sign } from "../nostr";
import { connectedRelayCount, postEvent, publishEvent } from "../relay";
import { useNavigate } from "react-router-dom";
import { nip19 } from "nostr-tools";
import { UserSearchMenu } from "./user";
import Picker from '@emoji-mart/react'
import { Tooltip } from "react-tippy";

let tag_regex = /#(\w+)/g
let note_regex = /@?note1[ac-hj-np-z02-9]{58}/gi
let pubkey_regex = /@?npub1[ac-hj-np-z02-9]{58}/gi
let regex = /(?<tag>#(\w+))|(?<note>@?note1[ac-hj-np-z02-9]{58})|(?<pubkey>@?npub1[ac-hj-np-z02-9]{58})/gi;
let remove_at = /^@/
let search_regex = /@(\S+)$/


export default function PostForm(props){
  let reply_to = props.reply_to
  const user = useSelector((state) => state.user.user)
  const [active, setActive] = useState(false)
  const [content, setContent] = useState("")
  const [searchTerm, setSearchTerm] = useState(["", 0])
  const textarea = useRef(null)
  const navigate = useNavigate()

  function onFocus(){
    setActive(true)
  }

  function onBlur(){
    // if(content == ""){
    //   setActive(false)
    // }
  }

  function insertAtPos(val, pos){
    setContent(content.slice(0, pos) + val + content.slice(pos))
  }

  function insertAtCursor(val){
    let pos = textarea.current.selectionStart
    insertAtPos(val, pos)
  }

  function handleChange(e){
    setContent(e.target.value)
    let cursorPosition = e.target.selectionStart
    let c = e.target.value.slice(0, cursorPosition)
    let index = c.search(search_regex)
    if(index !=-1){
      setSearchTerm([c.slice(index+1), index])
    }else{
      setSearchTerm(["", 0])
    }
  }

  function addUserMention(user){
    let npub = nip19.npubEncode(user.pubkey)
    let val = "@" + npub + " "
    setContent(content.slice(0, searchTerm[1]) + "@" + npub + " " +
      content.slice(searchTerm[1]+searchTerm[0].length+2))
    let pos = searchTerm[1] + npub.length + 2
    textarea.current.focus()
    textarea.current.setSelectionRange(pos, pos)
    setSearchTerm(["", 0])
  }
  
  useEffect(() => {
    let e = textarea.current
    e.style.height = e.scrollHeight + "px";
  }, [content])

  async function submit(){
    if(content != ""){
      let processed_content = content
      let tags = [["client", "tucan.to"]]
      let hashtags = content.match(tag_regex)
      if(hashtags){
        for(const t of hashtags){
          tags.push(["t", t.slice(1)])
        }
      }
      let note_mentions = content.matchAll(note_regex)
      if(note_mentions){
        for(const n of note_mentions){
          try{
            let note_id = nip19.decode(n[0].replace(remove_at, "")).data
            tags.push(["e", note_id, "", "mention"])
            processed_content = processed_content.replace(n[0], "#[" + (tags.length-1) + "]")
          }catch(e){}
        }
      }
      let user_mentions = content.matchAll(pubkey_regex)
      if(user_mentions){
        for(const p of user_mentions){
          try{
            let pubkey = nip19.decode(p[0].replace(remove_at, "")).data
            tags.push(["p", pubkey])
            processed_content = processed_content.replace(p[0], "#[" + (tags.length-1) + "]")
          }catch(e){}
        }
      }
      if(reply_to){
        if(reply_to.root_reply){
          tags.push(["e", reply_to.event_id, reply_to.received_by || "", "reply"])
          tags.push(["e", reply_to.root_reply.event_id, reply_to.root_reply.received_by || "", "root"])
        }else{
          tags.push(["e", reply_to.event_id, reply_to.received_by || "", "root"])
        }
        tags.push(["p", reply_to.user.pubkey])
        if(reply_to.mentions){
          let mentions = Object.values(reply_to.mentions)
          for(let i = 0; i < mentions.length; i++){
            let m = mentions[i]
            if(m.t == 'u'){
              tags.push(["p", m.pubkey])
            }
          }
        }
      }
      let event = {
        kind: 1,
        created_at: Math.floor(Date.now() / 1000),
        tags: tags,
        content: processed_content
      }
      if(connectedRelayCount() == 0){
        alert("You are not connected to any relays! Check the settings page to edit your relays.")
        return 
      }
      event = await sign(event)
      await postEvent(event)
      publishEvent(event)
      console.log(event)
      navigate(post_path(event.id))
    }
  }

  function selectEmoji(e){
    console.log(e)
    insertAtCursor(e.native)
  }

  return (
    <div className={"post-form" + 
      (props.reply ? " reply" : "") + 
      ((props.inline && !active) ? " inline" : "")}>
      <div className="post-form-body">
        <div className="post-form-avatar">
          <ProfilePicture src={(user && user.picture) ? user.picture : null} to={user ? profile_path(user.pubkey) : "/"} type="large" />
        </div>
        <div className="post-form-content">
          <UserSearchMenu term={searchTerm[0]} selectUser={addUserMention}>
            <textarea
            ref={textarea}
            placeholder={props.reply ? "Post your reply." : "What's happening?" } 
            rows={10}
            onFocus={onFocus}
            onBlur={onBlur}
            value={content}
            onChange={handleChange}
            ></textarea>
          </UserSearchMenu>
        </div>
      </div>
      <div className="post-form-buttons">
        <EmojiPickerMenu selectEmoji={selectEmoji} />
        <button className="btn blue-bg flat bold" disabled={!user || content=="" || !props.enabled}
          onClick={submit}>
          {props.reply ? "Reply" : "Post"}
        </button>
      </div>
    </div>
  )
}

let data = async () => {
  const response = await fetch(
    'https://cdn.jsdelivr.net/npm/@emoji-mart/data',
  )

  return response.json()
}
data()

export function EmojiPickerMenu(props){
  const [open, setOpen] = useState(false)
  let picker = <Picker data={data} onEmojiSelect={props.selectEmoji} theme={"light"} />
  return (
    <Tooltip
      html={picker}
      open={open}
      onRequestClose={() => {setOpen(false)}}
      position={props.position || "bottom"}
      interactive={true}
      theme="light"
    >
    <div className="emoji-btn btn" onClick={() => setOpen(!open)}>
      <i className="micon mood"></i>
    </div>
  </Tooltip>
  )
}