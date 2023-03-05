
import React, {useState, useEffect} from "react";
import { Link } from "react-router-dom";
import { Tooltip } from 'react-tippy';

import { nip19 } from "nostr-tools";
import { profile_path } from "../url_helpers";
import dayjs from "dayjs"

export function Pubkey(props){
  let npub = nip19.npubEncode(props.pubkey)
  let [expanded, setExpanded] = useState(false)
  return (
    <div className="pubkey" title={npub} onClick={() => setExpanded(!expanded)}>
      {expanded ? npub : npub.slice(0, 15) + "..."}
    </div>
  )
}

function timeSince(time){
  let now = dayjs()
  let diff = Math.trunc(now.diff(time)/1000)
  if(diff < 60){
    return diff + "s"
  }else if(diff < 60*60){
    return Math.trunc(diff/60) + "m"
  }else if(diff < 60*60*24){
    return Math.trunc(diff/(60*60)) + "h"
  }else if(now.year() == time.year()){
    return time.format('D MMM')
  }else{
    return time.format('D MMM YYYY')
  }
}

export function TimeSince(props){
  const [time_str, setTimeStr] = useState("")

  useEffect(() => {
    let time = dayjs(props.time)
    let now = dayjs()
    let diff = Math.trunc(now.diff(time)/1000)
    setTimeStr(timeSince(time))

    if(diff < 60*60){
      setInterval(() => setTimeStr(timeSince(time)), 60*1000)
    }else if(diff < 60*60*24){
      setInterval(() => setTimeStr(timeSince(time)), 60*30*1000)
    }
  }, [])

  return (
    <span className="time-since" title={props.time}>
      {time_str}
    </span>
  )
}

export function ReloadPosts(props){
  return (
    <div className="reload" onClick={props.reload}>
      {props.state=="loading" ? <Loader /> :
        <div className="reload-btn">
          {props.state=="ok" ? "Refresh" : "Retry"}
        </div>
      }
    </div>
  )
}

export function Loader(){
  return (
    <div className="loader"></div>
  )
}

export function useTitle(title, deps){
  useEffect(() => {
    if(title == ""){
      document.title = "Nostr"
    }else{
      document.title = title + " | Tucan"
    }
  }, deps)
}

export function Pagination(props){
  // page_size, page, total_items
  let total_pages = Math.ceil(props.total_items/props.page_size)
  const [currPage, setCurrPage] = useState(props.page)

  function handleChange(e){
    let val = e.target.value
    if(val.match(/^[0-9]*$/)){
      if(val=="" || (parseInt(val) <= total_pages && parseInt(val)>0)){
        setCurrPage(val)
      }
    }
  }

  function handleSubmit(e){
    e.preventDefault()
    getPage(currPage)
  }

  function incPage(ammount){
    let newPage = parseInt(currPage) + ammount
    if(newPage > 0 && newPage <= total_pages){
      setCurrPage(newPage)
      getPage(newPage)
    }
  }

  function getPage(page){
    page = parseInt(page)
    if(page){
      props.fetch(page, (page-1)*props.page_size, props.page_size)
    }
  }

  useEffect(() => {
    setCurrPage(props.page)
  }, [props.page])

  return (
    <div className="pagination">
      <div className="btn pagination" onClick={() => incPage(-1)}>
        <i className="micon chevron_left"></i>
      </div>
      <form onSubmit={handleSubmit}>
        <input type="text" 
          value={currPage} 
          onChange={handleChange}
          style={{width: ((currPage + "").length + 3) + "ch"}}
          ></input> 
      </form>
      / 
      <span>{total_pages}</span>
      <div className="btn pagination" onClick={() => incPage(1)}>
        <i className="micon chevron_right"></i>
      </div>
    </div>
  )
}

export function Menu(props){
  return (
    <Tooltip
      html={props.menu}
      open={props.open}
      onRequestClose={() => {props.setIsOpen(false)}}
      position={props.position || "top"}
      interactive={true}
      theme="light"
    >
      {props.children}
    </Tooltip>
  )
}