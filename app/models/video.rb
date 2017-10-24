class Video < MediaResource

  def ffmpeg_args(ffmpeg_movie_object)
    ffmpeg_args_template = DERIVATIVO[media_type + '_access_copy_settings']['ffmpeg_args']
    video_quality_constant = DERIVATIVO[media_type + '_access_copy_settings']['video_quality_constant']

    # Replace VIDEO_WIDTH and VIDEO_HEIGHT placeholders with actual video width and height
    video_width = ffmpeg_movie_object.width
    video_height = ffmpeg_movie_object.height
    bitrate = (video_quality_constant * video_width * video_height * ffmpeg_movie_object.frame_rate.to_f).ceil

    ffmpeg_args_template.
      gsub('{VIDEO_WIDTH}', video_width.to_s).
      gsub('{VIDEO_HEIGHT}', video_height.to_s).
      gsub('{BITRATE_VALUE}', bitrate.to_s).
      split(' ')
  end

end
