function dist_post_process(exp,varargin)
  
sm = findResource();

job = createJob(sm);

for subj=exp.subj
  for sess=subj.sess
    createTask(job, @prep_egi_data2(subj.id,sess.dir,varargin{:}))
  end
end

submit(job);
