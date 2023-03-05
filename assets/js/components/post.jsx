import React, {useEffect, useState} from "react";
import { Link } from "react-router-dom";
import { useNavigate } from "react-router-dom";
import ProfilePicture from "./profile_picture";
import { profile_path, user_at } from "../url_helpers";
import { TimeSince } from "../components/ui_elements"
import { nip19 } from "nostr-tools";
import dayjs from "dayjs";
import * as linkify from 'linkifyjs';

import localizedFormat from 'dayjs/plugin/localizedFormat';
import { useDispatch } from "react-redux";
import { addPost } from "../state/postSlice";
import { sign } from "../nostr";
import { postEvent, connectedRelayCount, publishEvent } from "../relay";
import { proxyImage } from "../image";
dayjs.extend(localizedFormat)

const media_regex = /^.*\.(bmp|jpg|jpeg|png|gif|webp|mp4|webm|mov)$/g;
const img_regex = /^.*\.(bmp|jpg|jpeg|png|gif|webp)$/g;
const video_regex = /^.*\.(mp4|webm|mov)$/g;
const mention_regex = /#\[[0-9]+\]/g;
let body_regex = /(?<mention>#\[[0-9]+\])|(?<tag>#(\w+))|(?<lnurl>(lnurl1|lnbc1)[ac-hj-np-z02-9]+)|(?<link>https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*))/gi;

export function TimelinePost(props){
  const navigate = useNavigate();
  let post = props.post
  let note = nip19.noteEncode(post.event_id)

  let [content, media] = juiceContent(post)
  let dispatch = useDispatch()

  function setLiked(){
    console.log({...post, liked: true})
    dispatch(addPost({...post, liked: true}))
  }

  return (
    <>
    <div className={"tl-post-wrapper ts" + (props.reply || props.replyLine ? " reply" : "")}>
      <div className="tl-post" onClick={() => {navigate("/post/" + note)}}>
        <div className="tl-post-trail">
          <div className={"tl-post-trail-line top " + (props.isReply ? "" : "hidden")}></div>
          <ProfilePicture src={post.user.picture} to={profile_path(post.user.pubkey)} type="large" />
          {(props.reply || props.thread || props.replyLine) && <div className="tl-post-trail-line"></div>}
        </div>
        <div className="tl-post-main">
          <div className="tl-post-sig">
            <Link to={profile_path(post.user.pubkey)} onClick={(e) => e.stopPropagation()} className="name">{post.user.name}</Link>
            <span className="at">{user_at(post.user)} ·  <TimeSince time={post.created_at} /> </span>
          </div>
          <div className="tl-post-body">{content}</div>
          {!props.hide_images && media.length > 0 && <PostCard url={media[0].value} />}
          <div className="post-buttons">
            <Buttons post={post} setLiked={setLiked} />
          </div>
        </div>
      </div>
      {props.thread &&
        <div className="tl-post-thread">
          <div className="tl-post-trail">
            <ProfilePicture src={post.user.picture} to={profile_path(post.user.pubkey)} type="small" />
          </div>
          <div className="tl-post-main">
            <Link to={"/post/" + post.id}>Show this thread</Link>
          </div>
        </div>
      }
    </div>
    {props.reply &&
      <TimelinePost post={props.reply} isReply={true}/>
    }
    </>
  )
}

export function ExpandedPost(props){
  let post = props.post
  let npub = nip19.npubEncode(post.user.pubkey)

  let [content, media] = juiceContent(post)
  return (
    <div className={"ex-post" + (props.isReply ? " reply" : "")}>
      <div className="ex-post-head">
        <div className="tl-post-trail nm">
          <div className={"tl-post-trail-line top " + (props.isReply ? "" : "hidden")}></div>
          <ProfilePicture src={post.user.picture} to={"/profile/" + post.user.pubkey} type="large" />
        </div>
        <div className="ex-post-sig">
          <Link to={profile_path(post.user.pubkey)} onClick={(e) => e.stopPropagation()} className="name">{post.user.name}</Link>
          <div className="at">{user_at(post.user)}</div>
        </div>
      </div>
      <div className="ex-post-body" >{content}</div>
      {!props.hide_images && media.length > 0 && <PostCard url={media[0].value} />}
      <div className="ex-post-date">
        {dayjs(post.created_at).format("h:mm A · MMM D, YYYY")}
      </div>
      <div className="post-buttons">
        <Buttons post={post} />
      </div>
    </div>
  )
}

function Buttons(props){
  let post = props.post
  let [liked, setLiked] = useState(post.liked)
  useEffect(() => {
    setLiked(post.liked)
  }, [post])
  
  async function handleLike(e){
    e.stopPropagation()
    if(!post.liked && !liked){
      if(connectedRelayCount() == 0){
        alert("You are not connected to any relays! Check the settings page to edit your relays.")
        return 
      }
      if(confirm("Are you sure you want to like this post?")){
        let tags = [
          ["client", "tucan.to"],
          ["e", post.event_id],
          ["p", post.user.pubkey]
        ]
    
        let event = {
          kind: 7,
          created_at: Math.floor(Date.now() / 1000),
          tags: tags,
          content: "+"
        }
        event = await sign(event)
        await postEvent(event)
        publishEvent(event)
        if(props.setLiked) props.setLiked()
        setLiked(true)
      }
    }
  }

  return(
    <>
      <div className="btn blue">
        <i className="micon reply"></i> <span>{post.reply_count > 0 && post.reply_count}</span>
      </div>
      {/* <div className="btn green">
        <i className="micon repost"></i> <span> </span>
      </div> */}
      {/* <div className="btn green">
        <i className="micon quote"></i> <span></span>
      </div> */}
      <div className="btn pink" onClick={handleLike}>
        <i className={"micon heart " + (post.liked || liked ? "liked fill" : "")}></i> <span>{post.like_count > 0 && post.like_count}</span>
      </div>
      {/* <div className="btn blue">
        <i className="micon share"></i> <span> </span>
      </div> */}
    </>
  )
}

function PostCard(props){
  let img
  if(props.url.match(img_regex)){
    img = true
  }

  let inner = (
    <div className="post-card ts" onClick={(e) => e.stopPropagation()}>
      {img ?
        <img src={proxyImage(props.url, 500, 500)}></img>
        :
        <video src={props.url} controls loop ></video>
      }
    </div>
  )
  if(img){
    inner = <a href={props.url} target="_blank">{inner}</a>
  }

  return (
    <div className="post-card-wrapper">
      {inner}
    </div>
  )
}


function sp(e){
  e.stopPropagation()
}

const newline_regex = /^\n+/g

function replaceMentions(text, mention_map){
  // text = text.replace(newline_regex, '');
  if(!mention_map) return text
  let res = []
  let pos = 0
  while ((array1 = mention_regex.exec(text)) !== null) {
    let start = mention_regex.lastIndex - array1[0].length
    let index = parseInt(array1[0].slice(2, -1))
    if(mention_map[index]){
      let m = mention_map[index]
      res.push(text.slice(pos, start))
      if(m.t=='p'){
        let note = nip19.noteEncode(m.event_id)
        res.push(<Link key={index + "m"} to={"/post/" + note} onClick={sp}>{"@" + note.slice(0,15) + "... "}</Link>)
      }else{
        res.push(<Link key={index + "m"} to={profile_path(m.pubkey)} onClick={sp}>{user_at(m)}</Link>)
      }
    }else{
      res.push(text.slice(pos, mention_regex.lastIndex))
    }
    pos = mention_regex.lastIndex
  }
  res.push(text.slice(pos, text.length))
  return res
}

function juiceContent(post){
  post.content = post.content || ""
  let links = linkify.find(post.content)
  links = links.filter((l) => l.type=='url')
  let media = links.filter((l) => l.value.match(media_regex))
  let omit_first = media.length>0

  let content = []
  let pos = 0
  let l
  for(let i = 0; i < links.length; i++){
    l = links[i]
    let link = l.value
    if(!link.startsWith("http")) link = "http://" + link
    content = content.concat(replaceMentions(post.content.slice(pos, l.start), post.mentions))
    if(true || i>0 || !omit_first){
      if(l.value.length<=25){
        content.push(<a href={link} onClick={sp} target="_blank" key={i + "l"} title={l.value}>{l.value}</a>)
      }else{
        content.push(<a href={link} onClick={sp} target="_blank" key={i + "l"} title={l.value}>{l.value.slice(0,25) + "..."}</a>)
      }
    }
    pos = l.end
  }
  content = content.concat(replaceMentions(post.content.slice(pos, post.content.length), post.mentions))
  return [content, media]
}
