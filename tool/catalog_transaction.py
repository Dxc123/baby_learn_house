"""Failure-safe multi-document publication; callers validate before writing."""
import json
import os
from pathlib import Path
def write_documents(root:Path,documents:dict[str,dict])->None:
    if not documents or any(k not in {'content','readings','stories'} for k in documents):raise ValueError('Invalid output')
    targets=[root/f'assets/data/{k}.json' for k in documents]
    previous=[p.read_bytes() if p.exists() else None for p in targets]
    temps=[p.with_suffix('.tmp') for p in targets]
    try:
        for temp,data in zip(temps,documents.values()):temp.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
        for temp,target in zip(temps,targets):os.replace(temp,target)
    except BaseException:
        for target,old in zip(targets,previous):
            if old is None:target.unlink(missing_ok=True)
            else:target.write_bytes(old)
        raise
    finally:
        for temp in temps:temp.unlink(missing_ok=True)
