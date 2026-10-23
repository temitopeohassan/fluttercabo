import { Link } from 'react-router-dom'
import { Empty } from '../components/ui'
import { useTitle } from '../lib/hooks'

export default function NotFound() {
  useTitle('Page not found')
  return <div className="card"><Empty title="Page not found" action={<Link className="btn btn-primary" to="/">Go to the dashboard</Link>}>That page does not exist or has moved.</Empty></div>
}
