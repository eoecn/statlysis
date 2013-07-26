# encoding: UTF-8
# TODO support mongoid

module Statlysis
  class Similar
    attr_accessor :id_to_text_hash_proc, :corpus, :matrix, :id_to_similar_ids
    include Common

    def initialize model_name, id_to_text_hash_proc
      # 初始化数据
      cron.id_to_text_hash_proc = id_to_text_hash_proc

      # 初始化表和模型
      cron.stat_table_name = [Statlysis.tablename_default_pre, "similar", model_name].compact.join("_")
      Utils.setup_pattern_table_and_model cron.stat_table_name

      cron.id_to_similar_ids = {}
      cron
    end

    def process
      logger.info "SimilarProcess #{cron.stat_model} at #{DateTime.now}"
      require 'gsl'
      require 'tf-idf-similarity'

      # 初始化文档
      logger.info "开始取出 cron.id_to_text_hash_proc"
      @id_to_text_hash = cron.id_to_text_hash_proc.call

      logger.info "开始把@id_to_text_hash转化为数组"
      as = @id_to_text_hash.to_a

      logger.info "开始把as slice为1200每次"
      as.each_slice(1200) do |a|
      logger.info "开始跑 #{a.size}  个条目的相似性"
      cron.corpus = TfIdfSimilarity::Collection.new
      a.each do |id, text|
        cron.corpus << TfIdfSimilarity::Document.new(text, :id => id)
      end
=begin
      @id_to_text_hash.each do |id, text|
        cron.corpus << TfIdfSimilarity::Document.new(text, :id => id)
      end
=end

      cron.matrix = cron.corpus.similarity_matrix
      matrix_array = cron.matrix.to_a

      # matrix的数组下标对应到真实的item_id
      matrix_idx_to_item_id_hash = {}
      cron.corpus.documents.each_with_index do |document, idx1|
        matrix_idx_to_item_id_hash[idx1] = document.id
      end

      # 取出matrix里各item的按相关度倒序的item_ids，并保存
      cron.corpus.documents.each_with_index do |document, idx1|
        _item_id_to_score = Hash.new 0
        matrix_array[idx1].each_with_index do |num, idx2|
          _item_id_to_score[matrix_idx_to_item_id_hash[idx2]] = (num.nan? ? 0.0 : num)
        end
        _item_id_to_score.delete document.id
        logger.info "对比文档："
        logger.info "#{document.id} # #{summary(document.id)}"
        logger.info "相关文档："
        _item_ids = _item_id_to_score.sort {|a1, b1| b1[1] <=> a1[1] }
        _item_ids[0..9].each do |item_id, score|
          logger.info "#{score} #  #{summary(item_id)}"
        end
        cron.id_to_similar_ids[document.id] = _item_ids[0..99].map(&:first)
        logger.info
      end

      # save results to database
      cron.id_to_similar_ids.each do |id, similar_ids|
        s = cron.stat_model.find_or_create(:pattern => id)
        s.update :result => similar_ids.to_json
      end
      end # @id_to_text_hash.to_a.each_slice(1000) do |a|

      return true
    end
    alias run process

    def summary doc_id
      @id_to_text_hash[doc_id].mb_chars[0..41].split("\n").join
    end

  end
end
